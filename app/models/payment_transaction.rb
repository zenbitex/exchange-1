class PaymentTransaction < ActiveRecord::Base
  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  STATE = [:unconfirm, :confirming, :confirmed]
  enumerize :aasm_state, in: STATE, scope: true

  validates_presence_of :txid

  has_one :deposit
  belongs_to :payment_address, foreign_key: 'address', primary_key: 'address'
  has_one :account, through: :payment_address
  has_one :member, through: :account

  after_update :sync_update

  aasm :whiny_transitions => false do
    state :unconfirm, initial: true
    state :confirming
    state :confirmed, after_commit: [:deposit_accept, :prime]

    event :check do |e|
      before :refresh_confirmations

      transitions :from => [:unconfirm, :confirming], :to => :confirming, :guard => :min_confirm?
      transitions :from => [:unconfirm, :confirming, :confirmed], :to => :confirmed, :guard => :max_confirm?
    end
  end

  def min_confirm?
    deposit.min_confirm?(confirmations)
  end

  def max_confirm?
    deposit.max_confirm?(confirmations)
  end

  def logger(attribute, payload)
    logger ||= Logger.new("#{Rails.root}/log/payment_transaction.log")
    logger.debug attribute
    logger.debug payload
  end

  def refresh_confirmations
    if ["btc", "bch", "btg"].include? deposit.currency
      raw = CoinRPC[deposit.currency].gettransaction(txid)
      self.confirmations = raw[:confirmations]
    elsif deposit.currency == "xrp"
      raw = CoinRPC['xrp'].tx([{
          "transaction": txid.to_s,
          "binary": false
        }])
      if raw["status"] == "success"
        self.confirmations = 3
      end
    elsif deposit.currency == "eth" || deposit.currency == "kbr"
      raw = CoinRPC['eth'].eth_getTransactionByHash([txid])
      current_block = CoinRPC['eth'].eth_blockNumber.to_i(16)
      block = raw["blockNumber"].to_i(16)
      self.confirmations = current_block - block
    elsif deposit.currency == "etc"
      raw = CoinRPC['etc'].eth_getTransactionByHash([txid])
      current_block = CoinRPC['etc'].eth_blockNumber.to_i(16)
      block = raw["blockNumber"].to_i(16)
      self.confirmations = current_block - block
    end 
    save!
  end

  def deposit_accept
    if deposit.may_accept?
      user_posite = PaymentSystem.find_by(txid: deposit.txid)
      if user_posite
        if user_posite.payment_amount != deposit.amount
          status =  PaymentSystem::STATUS_INVALID_AMOUNT
        else 
          status =  PaymentSystem::STATUS_SUCCESS
        end
        user_posite.update(status: status, amount_received: deposit.amount)
      end
      p "-------------^ewwetwetwet-ewwetewt-------depoist txid: #{deposit.txid}, amount: #{deposit.amount}"
      deposit.accept!
    end
  end

  def prime
    if ["btc", "bch", "btg"].include? deposit.currency && self.state != 1
      self.state = 1
      self.save!
    elsif deposit.currency == "xrp" && self.state != 1
      holding_xrp = Currency.find_by_code('xrp').address
      user_info = CoinRPC['xrp'].tx([{"transaction": txid, "binary": false}])
      logger "user_info", user_info
      fee = CoinRPC['xrp'].fee
      account_user = user_info["Destination"]
      amount = user_info["Amount"]
      user_account = PaymentAddress.find_by_address(account_user)
      if !user_account["active_ripple"]
        if amount.to_i > (20 * (10**6))
          user_account.update(active_ripple: true)
          amount_send = amount.to_i - (20 * (10**6)) - fee["max_queue_size"].to_i
        else
          amount_send = 0
        end
      amount_send
      else
        amount_send = amount.to_i
      end

      logger "amount_send2", amount_send
      if amount_send > 0
        sign = CoinRPC['xrp'].sign([{"offline": false,
                                  "secret": user_account["master_seed"],
                                  "tx_json": { "Account": account_user, 
                                               "Amount": amount_send.to_s, 
                                               "Destination": holding_xrp, 
                                               "TransactionType": "Payment"},
                                  "fee_mult_max": fee["max_queue_size"].to_i}])
        submit = CoinRPC['xrp'].submit([
           {'tx_blob': sign['tx_blob']}
        ])
        logger "submit", submit
      end
      self.state = 1
      self.save!
    elsif deposit.currency == "eth" && self.state != 1
      holding_eth = Currency.find_by_code('eth').address
      account_eth = CoinRPC['eth'].eth_getBalance(["#{self.address}", "latest"])
      balance = (account_eth.to_i(16) / ((10**18)).to_d).to_f
      if (self.address == holding_eth && balance < 0.001) || self.address == holding_eth || balance < 0.001
        self.save!
        return
      else
        logger "OK OK", txid
        send_to_ethereum(self.txid)
        self.state = 1
        self.save!
      end
    elsif deposit.currency == "etc" && self.state != 1
      holding_etc = Currency.find_by_code('etc').address
      account_etc = CoinRPC['etc'].eth_getBalance(["#{self.address}", "latest"])
      balance = (account_etc.to_i(16) / ((10**18)).to_d).to_f
      if (self.address == holding_etc && balance < 0.001) || self.address == holding_etc || balance < 0.001
        self.save!
        return
      else
        logger "OK OK", txid
        send_to_ethereum_classic(self.txid)
        self.state = 1
        self.save!
      end
    elsif deposit.currency == "kbr" && self.state != 1
      address_kbr_admin = Currency.find_by_code("kbr").address
      getbalance_ethereum = CoinRPC["eth"].eth_getBalance(["#{address_kbr_admin}", "latest"])
      balance = getbalance_ethereum.to_i(16) / ((10**18)).to_f
      if balance > 0.001
        send_eth_to_address_kbr(self.txid)
      else
        self.save!
        return
      end
    end
  end

  private

  def send_to_ethereum(txid)
    address_eth = Currency.find_by_code('eth').address
    password_eth = Currency.find_by_code('eth').password
    data = CoinRPC['eth'].eth_getTransactionByHash([txid])
    address = data["to"]
    if address_eth != address
      logger("address", "Alo gui gui vo dia chi chung")
      balance = CoinRPC['eth'].eth_getBalance(["#{address}", "latest"])
      begin
        unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address}", password_eth])
      rescue
        unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address}", ''])
      end
      gas = CoinRPC['eth'].eth_estimateGas([{"from": "#{address}", "to": address_eth, "value": "#{balance}"}])
      gasPrice = CoinRPC['eth'].eth_gasPrice
      value = balance.to_i(16) - gas.to_i(16) * gasPrice.to_i(16)
      value = '0x' + value.to_s(16)
      sendtransaction = CoinRPC['eth'].eth_sendTransaction([{"from": "#{address}", "to": address_eth, "gas": "#{gas}", "gasPrice": "#{gasPrice}", "value": "#{value}"}])
    else
      self.save!
      return
    end
  end

  def send_to_ethereum_classic(txid)
    address_etc = Currency.find_by_code('etc').address
    password_etc = Currency.find_by_code('etc').password
    data = CoinRPC['etc'].eth_getTransactionByHash([txid])
    address = data["to"]
    if address_etc != address
      balance = CoinRPC['etc'].eth_getBalance(["#{address}", "latest"])
      begin
        unlock_account = CoinRPC['etc'].personal_unlockAccount(["#{address}", password_etc])
      rescue
        unlock_account = CoinRPC['etc'].personal_unlockAccount(["#{address}", ''])
      end
      gas = CoinRPC['etc'].eth_estimateGas([{"from": "#{address}", "to": address_etc, "value": "#{balance}"}])
      gasPrice = CoinRPC['etc'].eth_gasPrice
      value = balance.to_i(16) - gas.to_i(16) * gasPrice.to_i(16)
      value = '0x' + value.to_s(16)
      sendtransaction = CoinRPC['etc'].eth_sendTransaction([{"from": "#{address}", "to": address_etc, "gas": "#{gas}", "gasPrice": "#{gasPrice}", "value": "#{value}"}])
    else
      self.save!
      return
    end
  end

  def send_eth_to_address_kbr(txid)
    detail_tx = CoinRPC["eth"].eth_getTransactionReceipt([txid])
    address_kbr_admin = Currency.find_by_code("kbr").address
    password_kbr_admin = Currency.find_by_code("kbr").password_admin
    contract_address = Currency.find_by_code("kbr").address_contract
    address_to = detail_tx["logs"].first["topics"][2][2..-1]
    data_balance = "0x70a08231" + address_to
    balance_holding_address = CoinRPC['eth'].eth_call([{"to": contract_address, "data": data_balance}, "latest"]).to_i(16)
    logger("balance_holding_address", balance_holding_address)
    if balance_holding_address >= 1000
        ActiveRecord::Base.transaction do
          gas_price = 2000 / ((10**12)).to_f
          gas_limit = 200000
          amount = (gas_price * gas_limit)

          value1 = (amount * (10**18).to_d).to_i
          value2 = '0x' + value1.to_s(16)
          unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address_kbr_admin}", "#{password_kbr_admin}"])
          gas = CoinRPC['eth'].eth_estimateGas([{"from": "#{address_kbr_admin}", "to": self.address, "value": "#{value2}"}])
          gasPrice = CoinRPC['eth'].eth_gasPrice
          
          txid = CoinRPC['eth'].eth_sendTransaction([{"from": "#{address_kbr_admin}", "to": self.address, "gas": "#{gas}", "gasPrice": "#{gasPrice}", "value": "#{value2}"}])
          logger "txid", txid

          save_send_eth_to_kbr(txid, address_kbr_admin, self.address, amount)

          self.state = 1
          self.save!
        end
    else
      self.save!
      return
    end
  end

  def save_send_eth_to_kbr(txid, address_from, address_destination, amount)
    PrimeTransaction.create(
      txid: txid,
      address_from: address_from,
      address_destination: address_destination,
      amount: amount,
      receive_at: Time.now,
      currency: 4
    )
  end

  def sync_update
    if self.confirmations_changed?
      ::Pusher["private-#{deposit.member.sn}"].trigger_async('deposits', { type: 'update', id: self.deposit.id, attributes: {confirmations: self.confirmations}})
    end
  end
end
