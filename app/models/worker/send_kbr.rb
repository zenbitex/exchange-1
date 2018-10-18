module Worker
  class SendKbr
    def logger(attribute, payload)
      logger ||= Logger.new("#{Rails.root}/log/send_kbr.log")
      logger.debug attribute
      logger.debug payload
    end
    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 120 # nothing result without sleep by query gettransaction api

      txid = payload[:txid]

      logger "txid", txid

      channel_key = 'kuberacoin'
      channel = DepositChannel.find_by_key(channel_key)
      raw     = get_raw_kbr(txid)
      logger "raw", raw
      send_kbr!(channel, raw)
    end

    def send_kbr!(channel, raw)
      return if raw[:gas] == nil
      
      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: raw[:address]).first
          Rails.logger.info "Kubera address not found, skip. txid: #{txid}, address: #{raw[:address]}, amount: #{raw[:amount]}"
          return
        end

        string_bit = "0000000000000000000000000000000000000000000000000000000000000000"
        password = Currency.find_by_code("kbr").password
        address_kbr_general = Currency.find_by_code("kbr").address
        contract_address = Currency.find_by_code("kbr").address_contract 

        begin
          unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{raw[:address]}", "#{password}"])
        rescue
          unlock_account = CoinRPC['eth'].personal_unlockAccount(["#{raw[:address]}", ''])
        end
        address_user_hex = raw[:address][2..-1]
        count_user_address_remain = 64 - address_user_hex.length
        address_user_bit = string_bit[0...count_user_address_remain] + address_user_hex
        data_balance = "0x70a08231" + address_user_bit
        amount = CoinRPC['eth'].eth_call([{"to": contract_address, "data": data_balance}, "latest"]).to_i(16)
        amount_hex = amount.to_s(16)
        count_bit_remain = 64 - amount_hex.length
        amount_bit = string_bit[0...count_bit_remain] + amount_hex

        address_hex = address_kbr_general[2..-1]
        count_address_remain = 64 - address_hex.length
        address_bit = string_bit[0...count_address_remain] + address_hex
        data = "0xa9059cbb" + address_bit + amount_bit
        gas = "0x" + 200000.to_s(16)
        gasPrice = "0x" + (2 * (10**9)).to_s(16)
        txid = CoinRPC['eth'].eth_sendTransaction([{"from": raw[:address], "gas": gas, "gasPrice": gasPrice ,"to": contract_address, "data": data}])

        save_send_kbr_to_general_address(txid, raw[:address], address_kbr_general, amount)

      end
    rescue
      Rails.logger.error "Failed to send Kbr to address general Kubera: #{$!}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def save_send_kbr_to_general_address(txid, address_from, address_destination, amount)
      PrimeTransaction.create(
        txid: txid,
        address_from: address_from,
        address_destination: address_destination,
        amount: amount,
        receive_at: Time.now,
        currency: 11
      )
    end

    def get_raw_kbr(txid)
      @data_test = CoinRPC['eth'].eth_getTransactionByHash(["#{txid}"])
      address = @data_test["to"]
      value = @data_test["value"].to_i(16) / ((10**18)).to_d
      gas = @data_test["gas"].to_i(16)
      @details = {:amount => value.to_f, :address => address, :gas => gas}
    end
  end
end
