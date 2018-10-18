module Private
  class SendcoinController < BaseController
    before_action :auth_activated!
    # before_action :auth_verified!
    # before_action :two_factor_activated!

    def new
      @currencies_summary = Currency.all.map(&:summary)
      if params[:coin_name]
        @coin_name = params[:coin_name]
      else
        @coin_name = "BTC"
      end

      # binding.pry

      # @currencies_summary.each do |c|
      #   if !c[:coinable]
      #     @currencies_summary.delete(c)
      #   end
      # end
      @sendcoin = Sendcoin.new
      member_id = current_user.id
      @price = 0
      # @price = coin_price @coin_name.downcase + "jpy"
      currency = @currencies_summary.find { |obj| obj[:name] == @coin_name}
      @coin_code = currency[:id]
      balance = Account.find_by(:member_id => member_id, :currency => @coin_code)
      @amount = (balance.amount - balance.locked).round(6).to_s

      if params[:sendcoin_action] == "change_coin"
        render json: {price: @price, amount: @amount}
        return
      end
      @email = EmailSendCoin.where(member_id: member_id)
    end

    def add_or_delete_email
      member_id = current_user.id
      if params[:sendcoin_action] == "add_email"
        if EmailSendCoin.find_by(email: params[:email], member_id: member_id).present?
          render json: {error: t('.email_exists')}
        else
          is_exists = (params[:email] != current_user.email && !Member.find_by(email: params[:email]).nil?)
          if is_exists
            email = EmailSendCoin.new(member_id: member_id, email: params[:email], label: params[:label])
            email.save
            render json: {finis: "success"}
          else
            render json: {error: t('.email_not_valid')}
          end
        end
      elsif params[:delete_email]
        email = EmailSendCoin.find_by(email: params[:delete_email], member_id: member_id)
        if email && email.destroy
          render json: {finis: "success"}
        else
          render json: {error: t('.email_not_valid')}
        end
      end
    end

    def create
      @sendcoin = Sendcoin.new(sendcoin_params)

      if Member.find_by(:email => @sendcoin.email).nil?
        redirect_to sendcoin_path, alert: t('.email_not_valid') and return
      end

      # user send
      currency_select = @sendcoin.currency
      currency_current_user = current_user.id
      currency_current_user_send = @sendcoin.currency
      balance_current_user_send = Account.find_by(:member_id => currency_current_user, :currency => currency_current_user_send).balance.to_f.round(3)

      # user revice
      email_user_revice = @sendcoin.email
      user_revice_1 = Member.find_by(:email => email_user_revice)
      user_revice_id = user_revice_1.id
      balance_user_revice = Account.find_by(:member_id => user_revice_id, :currency => currency_current_user_send)
      balance_user_revice = balance_user_revice.balance.to_f.round(3)
      balance_user_current_revice = @sendcoin.amount.to_f.round(3)

      if balance_current_user_send >= @sendcoin.amount.to_f.round(3)
        amount_current_user = balance_current_user_send - balance_user_current_revice
        amout_user_revice = balance_user_revice + balance_user_current_revice

        if currency_current_user != user_revice_id
          if @sendcoin.save
            # Account.where(member_id:currency_current_user, currency:currency_select).update_all(balance:amount_current_user)
            # Account.where(member_id:user_revice_id, currency:currency_select).update_all(balance:amout_user_revice)

            send_account = Account.find_by(member_id: currency_current_user, currency: currency_select)
            receive_account = Account.find_by(member_id: user_revice_id, currency: currency_select)
            send_account.lock!.sub_funds @sendcoin.amount.to_f.round(3), reason: Account::SEND_COIN, ref: nil
            receive_account.lock!.plus_funds @sendcoin.amount.to_f.round(3), reason: Account::RECEIVE_COIN, ref: nil

            Sendcoin.where(id:@sendcoin.id).update_all(user_id_source:currency_current_user, user_id_destination:user_revice_id)

            SendcoinMailer.sendcoin(@sendcoin.id).deliver
            SendcoinMailer.receivecoin(@sendcoin.id).deliver

            redirect_to sendcoin_path, notice: t('.successful')
          else
            error_msg = t('.cannot_send')
            if !@sendcoin.errors.messages.empty?
              errors = @sendcoin.errors.messages
              errors.each do |key, value|
                error_msg = errors[key][0]
              end
            end
            redirect_to sendcoin_path, alert: error_msg
          end
        else
          redirect_to sendcoin_path, alert: t('.cannot_send')
        end
      else
        redirect_to sendcoin_path, alert: t('.insufficient_fund')
      end
    end

    private

    def sendcoin_params
      params.require(:sendcoin).permit(:user_id_source, :user_id_destination, :amount, :currency, :email)
    end
  end
end
