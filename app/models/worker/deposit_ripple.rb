module Worker
  class DepositRipple
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/deposit_xrp.log")
      logger.debug attribute
      logger.debug payload
    end
    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      txid = payload[:txid]
      # status = payload[:status]
      

      # logger ||= Logger.new("#{Rails.root}/log/my.log")
      # file = File.open("#{Rails.root}/tmp/my.txt", "w")
      # file.write(txid)
      # file.close
      logger "txid", txid

      channel_key = 'ripple'
      channel = DepositChannel.find_by_key(channel_key)
      raw     = get_raw_ripple(txid)
      logger "raw", raw
      deposit_ripple!(channel, txid, raw)
    end

    def deposit_ripple!(channel, txid, raw)
      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: raw[:address]).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, address: #{raw[:address]}, amount: #{raw[:amount]}"
          return
        end
        logger "channel", channel
        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: 0,
        address: raw[:address],
        amount: raw[:amount].to_s.to_d,
        confirmations: raw[:confirmations],
        receive_at: Time.now,
        currency: channel.currency

        deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations
        deposit.submit!
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, detail: #{raw.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def get_raw_ripple(txid)
      # @data_test = CoinRPC['xrp'].eth_getTransactionByHash([txid.to_s])
      data = CoinRPC['xrp'].tx([{
          "transaction": txid.to_s,
          "binary": false
        }])
      # confirmations = status
      address = data["Destination"]
      value = data["Amount"].to_f / (10**6)
      details = {:amount => value, :confirmations => 0, :address => address}
    end
  end
end