require 'json_web_token'
module APIv2
  class Accounts < Grape::API
    helpers ::APIv2::NamedParams

    desc "Sign up", hidden: true
    params do
      requires :email, type: String
      requires :password, type: String
      requires :password_confirm, type: String
    end
    post "/account_signup" do
      identity = env['omniauth.identity'] || Identity.new({
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirm]
        })
      identity.save

      if identity.errors.any?
        json_fails 'signup error'
      else
        member = Member.new({
          email: params[:email],
          activated: 0,
          disabled: 0,
          api_disabled: 0
          })
        member.save!

        authentication = Authentication.new({
          member_id: member.id,
          provider: "identity",
          uid: identity.id
          })
        authentication.save
        Token::ActivationEmailMobile.create(member: member)

        json_success alg: 'HS256', access_token: jwt_sign(member.id)
      end
    end

    desc "LOGIN", hidden: true
    params do
      requires :email, type: String
      requires :password, type: String
    end
    post "/account_login" do
      result = Identity.find_by(email: params[:email]).try(:authenticate, params[:password])
      if result
        member = Member.find_by_email(params[:email])

        json_success(
          access_token: jwt_sign(member.id),
          activated: member.activated?,
          sn_code: member.sn_code,
          email: member.email
        )
      else
        json_fails 'login failed'
      end
    end

    #---------------------------------------------#
    desc "Account activate", hidden: true
    params do
      requires :active_code, type: String
    end
    post "/account_active" do
      jwt_token_authen!
      active_code = curr_member.tokens.where(:type => "Token::ActivationEmailMobile").last
      return json_fails('invalid_active_code', 500) if active_code.nil?

      if params[:active_code] == active_code.token
        active_code.confirm!
        gen_address curr_member

        json_success
      else
        json_fails 'invalid_active_code'
      end
    end

    #---------------------------------------------#
    desc "Resend active mail", hidden: true
    get "/resend_active_mail" do
      jwt_token_authen!

      return json_fails('This account has been active!') if curr_member.activated
      #send mail
      Token::ActivationEmailMobile.create(member: curr_member)

      json_success
    end

    desc "Send reset password mail", hidden: true
    params do
      requires :email, type: String
    end
    post "/reset_password_mail" do
      member = Member.find_by_email(params[:email])
      if member
        Token::ResetPasswordMobile.create(member: member)
        json_success(
          access_token: jwt_sign(member.id)
        )
      else
        json_fails 'invalid_email'
      end
    end

    desc "Confirm Reset password token", hidden: true
    params do
      requires :active_code, type: String
    end
    post "/confirm_reset_password" do
      jwt_token_authen!

      active_code = curr_member.tokens.where(:type => "Token::ResetPasswordMobile").last
      return json_fails('invalid_active_code', 500) if active_code.nil?

      if params[:active_code] == active_code.token
        active_code.confirm!
        new_password = '%08d' % SecureRandom.random_number(10000)
        curr_member.update_password new_password
        MemberMailer.new_password_mail(email: curr_member.email, new_password: new_password)
        json_success
      else
        json_fails 'invalid_active_code'
      end
    end

    desc "Change password", hidden: true
    params do
      requires :old_password, type: String
      requires :new_password, type: String
    end
    post "/change_password" do
      jwt_token_authen!
      identity = curr_member.identity
      if identity.authenticate(params[:old_password])
        curr_member.update_password params[:new_password]
        json_success
      else
        json_fails 'invalid_password'
      end
    end

    desc "Total asset", hidden: true
    params do
    end
    get "/total_asset" do
      jwt_token_authen!
      
      coincheck_price = {
        "btc" => 0,
        "etc" => 0,
        "eth" => 0,
        "xrp" => 0,
        "bch" => 0,
        "kbr" => 0
      }
      coincheck_price = Rails.cache.read("coincheck-price") || coincheck_price
      total_rate = 1
      total = 0
      curr_member.accounts.each do |ac|
        total += (ac.balance + ac.locked) * coincheck_price[ac.currency].to_f * total_rate
      end

      json_success(total_asset: total)

    end
  end
end
