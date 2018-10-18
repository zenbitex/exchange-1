module Private
  class BaseController < ::ApplicationController
    before_filter :no_cache, :auth_member!
    before_action :check_email_nil, :gen_sn_code

    private
    def phone_verify!
      if current_user
        phone_verified = TwoFactor.find_by(member_id: current_user.id, type: "TwoFactor::Sms")
        if !phone_verified.activated?
          redirect_to verify_sms_auth_path, notice: t('verify.sms_auths.notice')
        end
      end
    end

    def no_cache
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Sat, 03 Jan 2009 00:00:00 GMT"
    end

    def check_email_nil
      redirect_to new_authentications_email_path if current_user && current_user.email.nil?
    end

    def set_level
      if !current_user.nil?
        @phone_verified = TwoFactor.select('activated').where(member_id: current_user.id, type: "TwoFactor::Sms")
        if current_user.activated?
          acc_level = 1
          if current_user.id_document && current_user.id_document_verified?
            if !current_user.id_document.foreign.nil?
              if current_user.id_document.foreign.is?
                acc_level = 1
              elsif @phone_verified.activated?
                if current_user.id_document.is_address == 1
                  acc_level = 3
                else
                  acc_level = 2
                end
              end
            elsif @phone_verified.activated?
              if current_user.id_document.is_address == 1
                acc_level = 3
              else
                acc_level = 2
              end
            end
          end
          if(current_user.account_class != acc_level)
            current_user.update(account_class: acc_level)
          end

          if acc_level == 2 && current_user.affiliate_member_id
            if Member.count > 10000
              bonus_verfify_account
            end
          elsif acc_level == 3 && current_user.affiliate_member_id
            if Member.count > 10000
              bonus_verfify_account
              bonus_affiliate
            end
          end
        end
      end
    end

    def gen_sn_code
      if !current_user.nil?
        if current_user.sn_code.nil?
          begin
            sn_code = '%06d' % SecureRandom.random_number(1000000)
          end while Member.where(:sn_code => sn_code).any?
          current_user.update_attributes(:sn_code => sn_code)
        end
      end
    end

    def bonus_verfify_account
      parent_affiliate_user = Member.find_by_id(current_user.affiliate_member_id)
      affiliate_user = Affiliate.find_by_member_id(current_user.affiliate_member_id)
      bonus = 1000
      if parent_affiliate_user
        if !current_user.check_bonus_acc_active
          parent_affiliate_user.accounts.find_by(:currency => 1).lock!.plus_funds bonus, reason: Account::BONUS_AFFILIATE, ref: nil
          current_user.update_attributes(check_bonus_acc_active: true)
          if affiliate_user.bonus.nil?
            affiliate_user.bonus = 1000
          else
            affiliate_user.bonus = 1000 + affiliate_user.bonus
          end
          affiliate_user.save!
        end
      end
    end

    def bonus_affiliate
      parent_affiliate = Member.find_by_id(current_user.affiliate_member_id)
      affiliate = Affiliate.find_by_member_id(current_user.affiliate_member_id)
      bonus_money_verify = 2000
      bonus_money_trade = 2000
      # bonus for user if user upgrade account to lvl 3
      if parent_affiliate
        if !current_user.check_bonus_verify
          parent_affiliate.accounts.find_by(:currency => 1).lock!.plus_funds bonus_money_verify, reason: Account::BONUS_AFFILIATE, ref: nil
          current_user.update_attributes(check_bonus_verify: true)
          if affiliate.bonus.nil?
            affiliate.bonus = 2000
          else
            affiliate.bonus = 2000 + affiliate.bonus
          end
          affiliate.save!
        end
        ### Calculate value BTC trade in market and bonus for user if user trade BTC > 0.1
        if !current_user.check_bonus_trade
          btc_trade = sum_btc_trade
          if btc_trade > 0.1
            parent_affiliate.accounts.find_by(:currency => 1).lock!.plus_funds bonus_money_trade, reason: Account::BONUS_AFFILIATE, ref: nil
            current_user.update_attributes(check_bonus_trade: true)
            if affiliate.bonus.nil?
              affiliate.bonus = 2000
            else
              affiliate.bonus = 2000 + affiliate.bonus
            end
            affiliate.save!
          end
        end
      end
    end

    def sum_btc_trade
      btc_exchange_ask = Market.all.select {|x| x.base_unit == 'btc'}
      btc_exchange_code_ask = btc_exchange_ask.map(&:code)
      btc_ask = current_user.trades.select {|x| x["currency"].in? btc_exchange_code_ask}
      btc_ask_sum = btc_ask.sum(&:volume).to_f

      btc_exchange_bid = Market.all.select {|x| x.quote_unit == 'btc'}
      btc_exchange_code_bid = btc_exchange_bid.map(&:code)
      btc_bid = current_user.trades.select {|x| x["currency"].in? btc_exchange_code_bid}
      btc_bid_sum = btc_bid.sum(&:price).to_f

      return btc_ask_sum + btc_bid_sum
    end
  end
end
