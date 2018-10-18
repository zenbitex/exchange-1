module Worker
  class DepositKbr
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/deposit_kbr.log")
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
      # logger "txid", txid

      channel_key = 'kuberacoin'
      channel = DepositChannel.find_by_key(channel_key)
      raw     = get_raw_kbr(txid)
      logger "raw", raw
      deposit_kbr!(channel, txid, raw, payload[:address_to], payload[:amount])
      logger "amount", payload[:amount]
    end

    def deposit_kbr!(channel, txid, raw, address_to, amount)
      return if raw[:gas] == nil
      logger "debug", "OK OK"
      
      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: address_to).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, address: #{address_to}, amount: #{amount}"
          return
        end
        logger "address_to", address_to
        tx = PaymentTransaction::Normal.create! \
          txid: txid,
          txout: 0,
          address: address_to,
          amount: amount.to_s.to_d,
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
      Rails.logger.error "txid: #{txid}"
      Rails.logger.error $!.backtrace.join("\n")
    end
    def get_raw_kbr(txid)
      @data_test = CoinRPC['eth'].eth_getTransactionByHash(["#{txid}"])
      gas = @data_test["gas"].to_i(16)
      @details = {:confirmations => 0, :gas => gas}
    end
  end
end
