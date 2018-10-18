module Worker
  class DepositCoinAddress

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      payment_address = PaymentAddress.find payload[:payment_address_id]
      return if payment_address.address.present?

      currency = payload[:currency]
      if ["btc", "bch", "btg"].include? currency
        address  = CoinRPC[currency].getnewaddress
      elsif currency == 'eth'
        password = Currency.find_by_code('eth').password
        address  = CoinRPC['eth'].personal_newAccount([password])
      elsif currency == 'etc'
        password = Currency.find_by_code('etc').password
        address  = CoinRPC['etc'].personal_newAccount([password])
      elsif currency == 'kbr'
        password = Currency.find_by_code('kbr').password
        address  = CoinRPC['kbr'].personal_newAccount([password])
      elsif currency == 'xrp'
        random_sn = CoinRPC['xrp'].random()
        generate_sn = random_sn["random"]
        payment_info  = CoinRPC['xrp'].wallet_propose([{"passphrase": generate_sn}])
        payment_address.update(passphrase_xrp: generate_sn, master_seed: payment_info['master_seed'])
        address = payment_info['account_id']
      end

      if payment_address.update address: address
        ::Pusher["private-#{payment_address.account.member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: payment_address.as_json})
      end

    end

  end
end
