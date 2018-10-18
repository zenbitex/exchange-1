module Worker
  class DepositCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      channel_key = payload[:channel_key]
      txid = payload[:txid]

      channel = DepositChannel.find_by_key(channel_key)
      raw     = get_raw channel, txid

      raw[:details].each_with_index do |detail, i|
        detail.symbolize_keys!
        deposit!(channel, txid, i, raw, detail)
        Rails.logger.info "deposit #{channel_key}"
      end
    end

    def deposit!(channel, txid, txout, raw, detail)
      return if detail[:category] != "receive"
      ActiveRecord::Base.transaction do

        return if PaymentTransaction::Normal.find_by(txid: txid, txout: txout)
        
        currency_id = channel.currency_obj.id
        user_deposit = PaymentSystem.find_by(currency: currency_id, address: detail[:address])
        deposit_address = detail[:address]
        if user_deposit
          user_deposit.update(status: PaymentSystem::STATUS_CONFIRMING, txid: txid)
        else
          user_deposit = PaymentAddress.find_by(currency: currency_id, address: detail[:address])
        end
          
        unless user_deposit 
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{detail[:address]}, amount: #{detail[:amount]}"
          return
        end

        tx = PaymentTransaction::Normal.create! \
          txid: txid,
          txout: txout,
          address: deposit_address,
          amount: detail[:amount].to_s.to_d,
          confirmations: raw[:confirmations],
          receive_at: Time.at(raw[:timereceived]).to_datetime,
          currency: channel.currency

        if tx.member.nil?
          member = Member.find_by(id: user_deposit.member_id)
          account = member.accounts.find_by(currency: currency_id)
        else 
          member = tx.member
          account = tx.account
        end

        deposit = channel.kls.create! \
          payment_transaction_id: tx.id,
          txid: tx.txid,
          txout: tx.txout,
          amount: tx.amount,
          member: member,
          account: account,
          currency: tx.currency,
          confirmations: tx.confirmations

        deposit.submit!
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{detail.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def get_raw(channel, txid)
      channel.currency_obj.api.gettransaction(txid)
    end

  end
end
