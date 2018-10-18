class ColdWallet < ActiveRecord::Base

  attr_accessor :fee

  # validate :validate_fee_btc
  validates :amount, numericality: {greater_than: 0}
  validates_presence_of :address,:amount
  validate :ensure_hot_wallet_balance, on: :create
  validates :txid, uniqueness: true, allow_nil: true, on: :update
  # after_validation :validate_address

  def validate_fee_btc
    if ["btc", "bch"].include? self.currency
      self.fee > 0
    end
  end

  def sendtocoldwallet
    if ["btc", "bch"].include? self.currency
      listunspent = CoinRPC[self.currency].listunspent 0
      list = listunspent.sort_by{ |tx| -tx["amount"] }
      input = '['
      total_amount = 0
      list.each do |item|
        input = input + '{"txid": ' + "\"#{item["txid"].to_s}\"" + ', "vout": ' + "#{item["vout"].to_s}" + "}, "
        total_amount = total_amount + item["amount"].to_f
        break if total_amount > (self.amount.to_f + self.fee.to_f)
      end
      total_amount = (total_amount * 100000.to_f).floor / 100000.to_f
      send_amount = self.amount.to_f
      receive_amount = ((total_amount - send_amount - self.fee.to_f) * 100000.to_f).floor / 100000.to_f
      input = input.gsub(/\, $/,"") + "]"
      a = JSON.parse(input)
      begin
        receive_address = CoinRPC[self.currency].getnewaddress
        rawtx = CoinRPC[self.currency].createrawtransaction a, { "#{self.address}": send_amount, "#{receive_address}": receive_amount}
        signraw = CoinRPC[self.currency].signrawtransaction(rawtx)
        txid = CoinRPC[self.currency].sendrawtransaction(signraw[:hex])
        sum = self.amount.to_f + self.fee.to_f
        self.update_columns(txid: txid, fee: self.fee.to_f, sum: sum)
        self.save!
      rescue
        self.destroy
        errors.add :base, -> { I18n.t('activerecord.errors.models.cold_wallet.insufficient_funds') }
      end
    elsif self.currency == 'kbr'
      #send eth
      contract_address = Currency.find_by_code('kbr').address_contract
      address_kbr = Currency.find_by_code('kbr').address
      password_kbr = Currency.find_by_code('kbr').password_admin
      ##Calculate fee transaction
      string_bit = "0000000000000000000000000000000000000000000000000000000000000000"
      ##Withdraw for user
      begin
        unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address_kbr}", "#{password_kbr}"])
        #Conver amount to 32 bytes
        amount_tx_hex = self.amount.to_i.to_s(16)
        count_tx_remain = 64 - amount_tx_hex.length
        amount_bit_tx = string_bit[0...count_tx_remain] + amount_tx_hex

        address_hex = self.address[2..-1]
        count_address_remain = 64 - address_hex.length
        address_bit = string_bit[0...count_address_remain] + address_hex
        data = "0xa9059cbb" + address_bit + amount_bit_tx
        gas = "0x" + 200000.to_s(16)
        gasPrice = "0x" + (5 * (10**9)).to_s(16)
        txid = CoinRPC['eth'].eth_sendTransaction([{"from": address_kbr, "gas": gas, "gasPrice": gasPrice ,"to": contract_address, "data": data}])
        self.update_columns(txid: txid, fee: 0.001, sum: self.amount.to_f)
        self.save
      rescue
        self.destroy
        errors.add :base, -> { I18n.t('activerecord.errors.models.cold_wallet.insufficient_funds') }
      end
    elsif self.currency == 'eth'
      address_eth = Currency.find_by_code('eth').address
      password_eth_admin = Currency.find_by_code('eth').password_admin
      getbalance_ethereum = CoinRPC['eth'].eth_getBalance(["#{address_eth}", "latest"])
      balance = getbalance_ethereum.to_i(16) / ((10**18)).to_f
      value1 = (self.amount.to_f * (10**18).to_d).to_i
      value2 = '0x' + value1.to_s(16)
      begin
        unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address_eth}", "#{password_eth_admin}"])
        gas = CoinRPC['eth'].eth_estimateGas([{"from": "#{address_eth}", "to": self.address, "value": "#{value2}"}])
        gasPrice = CoinRPC['eth'].eth_gasPrice
        
        txid = CoinRPC['eth'].eth_sendTransaction([{"from": "#{address_eth}", "to": self.address, "gas": "#{gas}", "gasPrice": "#{gasPrice}", "value": "#{value2}"}])
        sum = self.amount.to_f + (gas.to_i(16) * gasPrice.to_i(16) / (10**18).to_d).to_f
        self.update_columns(txid: txid, fee: self.fee.to_f, sum: sum)
        self.save
      rescue
        self.destroy
        errors.add :base, -> { I18n.t('activerecord.errors.models.cold_wallet.insufficient_funds') }
      end          
    end
  end

  def validate_address?
    if ["btc", "bch"].include? self.currency
      result = CoinRPC[currency].validateaddress(address)
      if result.nil? || (result[:isvalid] == false)
        errors.add(:address, :invalid, message: 'is Invalid')
        return false
      elsif (result[:ismine] == true) || PaymentAddress.find_by_address(address)
        errors.add(:address, :hot_wallet, message: 'is in Hot wallet')
        return false
      else
        return true
      end
    elsif currency == "kbr" || currency == "eth"
      # validate eth address
      if is_address_ethereums(address) == false
        errors.add(:address, :invalid, message: 'is Invalid')
        return false
      else
        return true
      end
    end
  end

  def is_address_ethereums(address)
    regex1 = /^(0x)?[0-9a-f]{40}$/i
    regex2 = /^(0x)?[0-9A-F]{40}$/
    if !(address =~ regex1)
      return false
    elsif (address =~ regex1) || (address =~ regex2)
      return true
    end
  end

  def ensure_hot_wallet_balance
    if amount.nil? or amount >= CoinRPC[currency].safe_getbalance
      errors.add :base, -> { I18n.t('activerecord.errors.models.cold_wallet.currency_balance_is_poor') }
    end
  end
end
