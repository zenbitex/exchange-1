module Worker
  class WithdrawRipple
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/withdraw_ripple.log")
      logger.debug attribute
      logger.debug payload
    end

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        withdraw.whodunnit('Worker::WithdrawRipple') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.almost_done?
        address_ripple = Currency.find_by_code(withdraw.currency).address
        secret_ripple = Currency.find_by_code(withdraw.currency).assets['accounts'][0]['secret']
        getbalance_ripple = CoinRPC['xrp'].account_info(["account": "#{address_ripple}", "strict": true, "ledger_index": "current", "queue": true])
        logger "getbalance_ripple", getbalance_ripple
        fee = CoinRPC['xrp'].fee
        balance = getbalance_ripple['account_data']['Balance'].to_i
        amount = (withdraw.amount.to_f * (10**6)).to_i

        raise Account::BalanceError, 'Insufficient coins' if balance < amount

        if withdraw.destination_tag
          sign = CoinRPC['xrp'].sign([{"offline": false,
                                    "secret": secret_ripple,
                                    "tx_json": { "Account": address_ripple, 
                                                 "Amount": amount.to_s, 
                                                 "Destination": withdraw.fund_uid,
                                                 "DestinationTag": withdraw.destination_tag.to_s,
                                                 "TransactionType": "Payment"},
                                    "fee_mult_max": fee['drops']['median_fee'].to_i}])
        else
          sign = CoinRPC['xrp'].sign([{"offline": false,
                                    "secret": secret_ripple,
                                    "tx_json": { "Account": address_ripple, 
                                                 "Amount": amount.to_s, 
                                                 "Destination": withdraw.fund_uid, 
                                                 "TransactionType": "Payment"},
                                    "fee_mult_max": fee['drops']['median_fee'].to_i}])
        end

        logger "sign", sign
        
        submit = CoinRPC['xrp'].submit([
           {'tx_blob': sign['tx_blob']}
        ])
        txid = submit['tx_json']['hash']
        logger "txid", txid

        withdraw.whodunnit('Worker::WithdrawRipple') do
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