module Withdraws
  module Withdrawable
    extend ActiveSupport::Concern

    included do
      before_filter :fetch
    end

    def create
      param_currency = params[:withdraw][:currency]

      if captcha_invalid?
        render json: {content: I18n.t('private.withdraws.create.invalid_captcha'), type: "captcha"},  status: 403
      elsif current_user.two_factors.activated?
        if check_two_factor
          if check_address.present?
            render json: check_address, status: 403 and return
          end
          @withdraw = model_kls.new(withdraw_params)

          if ["btc", "bch", "btg"].include? param_currency
            if @withdraw.sum.to_f < 0.005
              render json: {content: I18n.t("private.withdraws.create.limit_amount_withdraw_btc"), type: "limit_amount_withdraw"},  status: 403
            else
              withdraw_save
            end
          elsif param_currency == "eth" || param_currency == "etc"
            if @withdraw.sum.to_f < 0.1
              render json: {content: I18n.t("private.withdraws.create.limit_amount_withdraw_eth"), type: "limit_amount_withdraw"},  status: 403
            else
              withdraw_save
            end
          elsif param_currency == "kbr"
            account_user_eth = Account.where(member_id: withdraw_params[:member_id], currency: 4).first
            if @withdraw.sum.to_f < 1000
              render json: {content: I18n.t("private.withdraws.create.limit_amount_withdraw_kbr"), type: "limit_amount_withdraw"},  status: 403
            elsif account_user_eth.balance < 0.005
              render json: {content: I18n.t('private.withdraws.create.insufficient_balance_ethereum', {amount: 0.005}), type: "two_factors_error1"},  status: 403
            else
              withdraw_save
            end
          elsif param_currency == "jpy"
            if current_user.bank_account
              @withdraw.assign_attributes :bank_account_id => current_user.bank_account.id
              withdraw_save
            else
              render json: {content: I18n.t("private.withdraws.create.bank_account"), type: "bank_account"},  status: 403
            end
          elsif param_currency == "xrp"
            load_balance_sum_address
            account_flag = CoinRPC["xrp"].account_info([{
                            "account": @destination_address,
                            "strict": true,
                            "ledger_index": "current",
                            "queue": true
                          }])
            if !account_flag["error"]
              if account_flag["account_data"].present? && account_flag["account_data"]["Flags"] != 0 && params[:withdraw][:destination_tag].nil?
                render json: {content: I18n.t("private.withdraws.create.missing_destination_tag"), type: "missing_destination_tag"},  status: 403
              elsif account_flag["account_data"].present? && account_flag["account_data"]["Flags"] == 0 && params[:withdraw][:destination_tag].present?
                render json: {content: I18n.t("private.withdraws.create.dont_have_destination_tag"), type: "dont_have_destination_tag"},  status: 403
              else
                if (@balance - @sum) > 20
                  withdraw_save
                else
                  render json: {content: I18n.t("private.withdraws.create.limit_amount_withdraw"), type: "limit_amount_withdraw"},  status: 403
                end
              end
            else
              if account_flag["validated"].present?
                if @sum < 20
                  render json: {content: I18n.t("private.withdraws.create.limit_amount_active_account"), type: "limit_amount_active_account"},  status: 403
                else
                  if (@balance - @sum) > 20
                    withdraw_save
                  else
                    render json: {content: I18n.t("private.withdraws.create.limit_amount_withdraw"), type: "limit_amount_withdraw"},  status: 403
                  end
                end
              else
                render json: {content: I18n.t("private.withdraws.create.error_withdraw_address"), type: "error_withdraw_address"},  status: 403
              end
            end
          end
        else
          render json: {content: I18n.t("private.withdraws.create.two_factors_error"), type: "two_factors_error"},  status: 403
        end
      else
        render json: {content: I18n.t("private.withdraws.create.active_phone_number"), type: "two_factors_error1"},  status: 403
      end
    end

    def duplication_message_delete(messages)
      @index = 0
      @length = messages.length
      until @index >= @length - 1  do
        @index1 = @index + 1
        until @index1 >= @length  do
          if messages[@index1] == messages[@index]
            messages.delete_at(@index1)
            @length =  messages.length
          else
            @index1 += 1
          end
        end
        @index += 1
      end
      messages
    end

    def destroy
      Withdraw.transaction do
        @withdraw = current_user.withdraws.find(params[:id]).lock!
        @withdraw.cancel
        @withdraw.save!
      end
      render nothing: true
    end

    private

    def fetch
      @account = current_user.get_account(channel.currency)
      @model = model_kls
      @fund_sources = current_user.fund_sources.with_currency(channel.currency)
      @assets = model_kls.without_aasm_state(:submitting).where(member: current_user).order(:id).reverse_order.limit(10)
    end

    def withdraw_params
      params[:withdraw][:currency] = channel.currency
      if channel.currency == "jpy"
        params[:withdraw][:fund_uid] = current_user.bank_account.account_number
        params[:withdraw][:fund_extra] = current_user.bank_account.bank_name
        params.require(:withdraw).permit(:fund_uid, :fund_extra, :member_id, :currency, :sum)
      else
        params[:withdraw][:member_id] = current_user.id
        params.require(:withdraw).permit(:fund_source, :member_id, :currency, :sum, :destination_tag)
      end
    end

    def withdraw_save
      if @withdraw.save
        if params[:withdraw][:currency] == 'kbr'
          account_user_eth = Account.where(member_id: withdraw_params[:member_id], currency: 4).first
          account_user_eth.lock!.lock_funds 0.005, reason: Account::KBR_FEE, ref: nil
        end
        @withdraw.submit!
        render json: {content: I18n.t('private.withdraws.create.success', {currency: params[:withdraw][:currency].upcase})},  status: 200
      else
        render json: {content: duplication_message_delete(@withdraw.errors.full_messages).join(', '), type: "withdraw_error"},  status: 403
      end
    end

    def check_two_factor
      two_factor_auth_verified_withdraw? || !current_user.security.two_factor["Withdraw"]
    end

    def load_balance_sum_address
      account_amout = Account.where(member_id: current_user.id, currency: 5)
      @balance =  account_amout[0]["balance"].to_f
      @sum = params[:withdraw][:sum].to_f

      @destination_address = FundSource.where(id: params[:withdraw][:fund_source]).pluck(:uid).first
    end

    def check_address
      error = {}
      if withdraw_params[:currency] != "jpyt"
        fund_uid = FundSource.find_by_id(withdraw_params[:fund_source]).uid
        currency_id = Currency.code_to_id(withdraw_params[:currency])
        address_user = current_user.accounts.find_by_currency(currency_id).payment_address.address

        if address_user == fund_uid
          error = {content: I18n.t('private.withdraws.create.address_same'), type: "two_factors_error1"}
        elsif PaymentAddress.find_by_address(fund_uid)
          error = {content: I18n.t('private.withdraws.create.address_hotwallet'), type: "two_factors_error1"}
        else
          check_address_manual = validate_address(withdraw_params[:currency], fund_uid, address_user)
          if check_address_manual[:error]
            error = {content: I18n.t('private.withdraws.create.address_error'),
              type: "two_factors_error1"}
          end
        end
      end
    end

    def validate_address(currency, fund_uid, address_user)
      case currency
      when 'btc', 'tao', 'bch'
        result = CoinRPC["btc"].validateaddress(fund_uid)
        if result.nil? || (result[:isvalid] == false)
          return {state: false, error: "address_error"}
        else
          return {state: true}
        end
      when 'xrp'
        result = CoinRPC['xrp'].account_info([{
            "account": fund_uid,
            "strict": true,
            "ledger_index": "current",
            "queue": true
          }])
        if result.nil? || result['validated'].nil?
          return {state: false, error: "address_error"}
        else
          return {state: true}
        end
      when 'eth', 'etc', 'kbr'
        if is_address_ethereums(fund_uid) == false
          return {state: false, error: "address_error"}
        else
          return {state: true}
        end
      end
    end

    def is_address_ethereums(address)
      regex1 = /^(0x)?[0-9a-f]{40}$/i
      regex2 = /^(0x)?[0-9A-F]{40}$/
      if !(address =~ regex1)
        return false
      elsif (address =~ regex1) || (address =~ regex2)
        return true
      end
    end
  end
end
