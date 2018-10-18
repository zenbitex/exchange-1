module Worker
  class WithdrawKbr
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/withdraw_kbr.log")
      logger.debug attribute
      logger.debug payload
    end

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        logger "payload", payload[:id]

        withdraw.whodunnit('Worker::WithdrawKbr') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.almost_done?
          contract_address = Currency.find_by_code(withdraw.currency).address_contract
          address_kbr = Currency.find_by_code(withdraw.currency).address
          password_kbr = Currency.find_by_code(withdraw.currency).password_admin
          account_user_eth = withdraw.member.accounts.find_by_currency(4)
          ##Calculate fee transaction
          string_bit = "0000000000000000000000000000000000000000000000000000000000000000"


          ##Withdraw for user

          address_kbr_hex = address_kbr[2..-1]
          count_address_kbr_remain = 64 - address_kbr_hex.length
          address_kbr_bit = string_bit[0...count_address_kbr_remain] + address_kbr_hex
          data_balance = "0x70a08231" + address_kbr_bit
          balance_holding_address = CoinRPC['eth'].eth_call([{"to": contract_address, "data": data_balance}, "latest"])
          balance = balance_holding_address.to_i(16)
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum

          logger "balance", balance

          unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{address_kbr}", "#{password_kbr}"])
          #Conver amount to 32 bytes
          amount_tx_hex = withdraw.amount.to_i.to_s(16)
          count_tx_remain = 64 - amount_tx_hex.length
          amount_bit_tx = string_bit[0...count_tx_remain] + amount_tx_hex

          address_hex = withdraw.fund_uid[2..-1]
          count_address_remain = 64 - address_hex.length
          address_bit = string_bit[0...count_address_remain] + address_hex
          data = "0xa9059cbb" + address_bit + amount_bit_tx
          txid = CoinRPC['eth'].eth_sendTransaction([{"from": address_kbr, "to": contract_address, "data": data}])

          logger "txid", txid
          account_user_eth.lock!.unlock_and_sub_funds 0.005, locked: 0.005, reason: Account::WITHDRAW_KBR, ref: self

        withdraw.whodunnit('Worker::WithdrawKbr') do
          withdraw.update_column :txid, txid
          # withdraw.succeed! will start another transaction, cause
          # Account after_commit callbacks not to fire
          withdraw.succeed
          withdraw.save!
        end
      end
    end
  end
end
