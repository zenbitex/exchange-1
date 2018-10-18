module Private
  class APIPaymentController < BaseController
    
    def index
      # binding.pry
      @api_payment = APIPayment.find_by(member_id: current_user.id)
    end

    def create_api
      @api_payment = APIPayment.find_by(member_id: current_user.id)
      if @api_payment.nil?
        member_id = current_user.id
        access_key = create_key(member_id, 32)
        secret_key = create_key(member_id, 48) 
        APIPayment.create(member_id: member_id, access_key: access_key, secret_key: secret_key, is_lock: false)
      end
      redirect_to payment_system_path
    end
    
    def create_key member_id = 1, length = 32
      time_current = Time.now.to_i.to_s
      data = rand(97..122).chr + member_id.to_s + rand(97..122).chr + time_current
      length = length - data.length
      key = ""
      index = 0
      while(true)
        char = rand(48..122).chr
        if char < '0' || (char > '9' && char < 'A') || (char > 'Z' && char < 'a') || char > 'z'
          next
        end
        index += 1
        if index >= length
          break
        end
        key += char
      end
      key + data
    end
  end
end