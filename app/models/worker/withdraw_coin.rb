module Worker
  class WithdrawCoin
    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        withdraw.whodunnit('Worker::WithdrawCoin') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.almost_done?

        tx_fee = FeeTrade.find_by(:currency => withdraw.currency.value).amount.to_f || 0.002

        listunspent = CoinRPC[withdraw.currency].listunspent 0
        list = listunspent.sort_by{ |tx| -tx["amount"] }
        input = '['
        total_amount = 0
        list.each do |item|
          input = input + '{"txid": ' + "\"#{item["txid"].to_s}\"" + ', "vout": ' + "#{item["vout"].to_s}" + "}, "
          total_amount = total_amount + item["amount"].to_f
          break if total_amount > (withdraw.amount.to_f + tx_fee.to_f)
        end

        total_amount = (total_amount * 100000.to_f).floor / 100000.to_f
        if total_amount < withdraw.sum
          withdraw.error!
          withdraw.save!
          raise Account::BalanceError, 'Insufficient coins'
        end
        input = input.gsub(/\, $/,"") + "]"
        a = JSON.parse(input)


        begin
          receive_address = CoinRPC[withdraw.currency].getnewaddress
          rawtx = CoinRPC[withdraw.currency].createrawtransaction a, { "#{withdraw.fund_uid}": withdraw.amount.to_f, "#{receive_address}": ((total_amount - withdraw.amount.to_f - tx_fee.to_f)*100000.to_f).floor/100000.to_f}
          signraw = CoinRPC[withdraw.currency].signrawtransaction(rawtx)
          txid = CoinRPC[withdraw.currency].sendrawtransaction(signraw[:hex])
        rescue
          withdraw.error!
          withdraw.save!
          Rails.logger.info "Withdraw id = #{withdraw.id} fail because Insufficient #{withdraw.currency} on wallet!!!"
          return
        end

        withdraw.whodunnit('Worker::WithdrawCoin') do
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
