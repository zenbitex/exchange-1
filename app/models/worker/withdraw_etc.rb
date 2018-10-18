module Worker
  class WithdrawEtc
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/withdraw_etc.log")
      logger.debug attribute
      logger.debug payload
    end

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        logger "payload", payload[:id]

        withdraw.whodunnit('Worker::WithdrawEtc') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.almost_done?
          address_etc = Currency.find_by_code(withdraw.currency).address
          password_etc_admin = Currency.find_by_code(withdraw.currency).password_admin
          getbalance_ethereum = CoinRPC[withdraw.currency].eth_getBalance(["#{address_etc}", "latest"])
          balance = getbalance_ethereum.to_i(16) / ((10**18)).to_f

          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum

          logger "balance", balance

          value1 = (withdraw.amount * (10**18).to_d).to_i
          value2 = '0x' + value1.to_s(16)
          unlock_account = CoinRPC['etc'].personal_unlockAccount(["#{address_etc}", "#{password_etc_admin}"])
          gas = CoinRPC['etc'].eth_estimateGas([{"from": "#{address_etc}", "to": withdraw.fund_uid, "value": "#{value2}"}])
          gasPrice = CoinRPC['etc'].eth_gasPrice
          
          txid = CoinRPC['etc'].eth_sendTransaction([{"from": "#{address_etc}", "to": withdraw.fund_uid, "gas": "#{gas}", "gasPrice": "#{gasPrice}", "value": "#{value2}"}])

          logger "txid", txid

        withdraw.whodunnit('Worker::WithdrawEtc') do
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
