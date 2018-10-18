module APIv2
  class Payment < Grape::API

    post "/check_key" do
      user_payment = current_user
      if user_payment[:success] != false
        user_payment = response_success("Checked successfully")
      end
      return user_payment
      # present current_user, with: APIv2::Entities::Member
    end

    post "/address_payment" do
      user_payment = current_user
      if user_payment[:success] == false
        return user_payment 
      end
      member_id = user_payment.member_id
      payment_amount = params[:amount].to_f
      if payment_amount == 0
        return response_error("Payment amount is not valid")
      end
      currency = params[:currency]
      payment_infor = params[:payment_infor]
      address = create_address currency

      if address.nil?
        return response_error("Server can't create payment address width #{params[:currency]}")
      end
      currency_id = Currency.find_by_code(currency).id
      payment = PaymentSystem.create(member_id: member_id, payment_amount: payment_amount, address: address, payment_infor: payment_infor, currency: currency_id)
      payment_id = Time.now.to_i.to_s + payment.id.to_s + member_id.to_s
      if payment.update(payment_id: payment_id)
        data = {payment_id: payment_id, payment_address: address, access_key: params[:access_key], amount: payment_amount, currency: currency}
        return response_success data
      else 
        return response_error("Server busy")
      end

    end

    post "/query_payment" do
      # user_payment = check_signature
      user_payment = current_user
      if user_payment[:success] == false
        return user_payment 
      end

      member_id = user_payment.member_id
      payment_id = params[:payment_id]
      if payment_id.nil?
        return response_error("Payment id can't empty.")
      end
      payment = PaymentSystem.find_by(payment_id: payment_id, member_id: member_id)
      if payment.nil?
        return response_error("Payment id #{payment_id} does not exist.")
      end

      infor = payment.as_json
      infor["currency"] = Currency.find_by_id(payment.currency).code
      data = infor.slice!("id", "member_id")
      return response_success data
    end

  end
end
