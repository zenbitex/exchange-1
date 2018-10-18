module APIv2
  module Helpers

    def current_user
      access_key = params[:access_key]
      user_payment = APIPayment.find_by(access_key: access_key)
      if user_payment.nil?
        return response_error("The access key #{access_key} does not exist.")
      end
      user_payment
    end

    def check_signature
      user_payment = current_user
      if infor[:success] == false
        return user_payment 
      end
      payload = params.select {|k,v| !%w(route_info signature format).include?(k) }
      payload = URI.unescape(payload.to_param)
      signature = OpenSSL::HMAC.hexdigest 'SHA256', user_payment.secret_key, payload
      
      if signature != params[:signature]
        return response_error("The signature #{params[:signature]} is incorrect.")
      else
        return user_payment
      end
    end

    def create_address currency = "btc"
      begin
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
        return address
      rescue Exception => e
        return nil
      end
    end

    def response_error message
      {success: false, message: message}
    end

    def response_success message
      {success: true, message: message}
    end
  end
end
