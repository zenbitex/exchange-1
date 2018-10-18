class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :auth_member!, only: :destroy
  before_action :auth_anybody!, only: [:new, :failure]
  before_action :add_auth_for_facebook
  before_action :add_auth_for_twitter
  before_action :load_member, only: [:wait_activation, :send_email_activation]

  helper_method :require_captcha?

  def new
    @identity = Identity.new
  end

  def create
    if params[:captcha]
      params[:captcha] = params[:captcha].zen_to_han
    end

    if !require_captcha? || simple_captcha_valid?
      @member = Member.from_auth(auth_hash)
    end

    if @member
      check_affiliates(@member, params)

      if @member.activated?
        if @member.disabled? || @member.is_lock?
          failure_auth t('.error')
        else
          verifi_two_factor
        end
      else
        redirect_to wait_activation_path(email: @member.email)
      end
    else
      failure_auth t('.error_login')
    end
  end

  def failure
    increase_failed_logins
    redirect_to signin_path, alert: t('.error')
  end

  def destroy
    #Identity.where(email: current_user.email).update_all(is_login: false)
    clear_all_sessions current_user.id
    reset_session
    redirect_to root_path
  end

  def wait_activation
    if @member.activated?
      redirect_to signin_path and return
    end
  end

  def send_email_activation
    unless @member.activated?
      @member.send_activation
      redirect_to :back
    end
  end

  private

  def load_member
    @member = Member.find_by email: params[:email]
    unless @member
      redirect_to root_url and return
    end
  end


  def verifi_two_factor
    two_factor_app = @member.two_factors.by_type("app")
    @member.create_securities unless @member.security
    if !two_factor_app.activated? || !@member.two_factor_login?
      login_to_setting_page(@member)
    else
      if params[:two_factor].blank?
        failure_auth t('.error_gg_auth')
      else
        two_factor_app.assign_attributes({"otp" => params[:two_factor]})
        if two_factor_app.verify?
          login_to_setting_page(@member)
        else
          failure_auth t('.error_login')
        end
      end
    end

  end

  def failure_auth message
    increase_failed_logins
    redirect_to signin_path, alert: message and return
  end

  def login_to_setting_page(member)
    clear_failed_logins
    reset_session rescue nil
    session[:member_id] = @member.id
    session[:two_factors] = true
    save_session_key member.id, cookies['_exchangepro_session']
    save_signup_history member.id
    if session[:active_email].nil? && member.send_email_login?
      MemberMailer.notify_signin(member.id).deliver if member.activated?
    end

    redirect_back_or_funds_page
  end

  def check_referrer_code
    if params[:action] == "create"
      referrer_code = params[:referrer_code]
      if !referrer_code.nil? && referrer_code != ""
        member_referrer = Member.find_by(sn_code: referrer_code)
        if member_referrer
          @member.update_attributes(referrer_member_id: member_referrer.id)
        end
      end
    end
  end

  def check_affiliates(member, params)
    #track only register case
    if params[:email] && params[:password_confirmation]
      if request.env['affiliate.tag'] && affiliate = Member.find_by_affiliate_code(request.env['affiliate.tag'])
        @member.update_attributes(affiliate_member_id: affiliate.id)
      end
    end
  end

  def require_captcha?
    failed_logins > 10
  end

  def failed_logins
    Rails.cache.read(failed_login_key) || 0
  end

  def increase_failed_logins
    Rails.cache.write(failed_login_key, failed_logins+1)
  end

  def clear_failed_logins
    Rails.cache.delete failed_login_key
  end

  def failed_login_key
    "exchangepro:session:#{request.ip}:failed_logins"
  end

  def auth_hash
    @auth_hash ||= env["omniauth.auth"]
  end

  def add_auth_for_facebook
    if current_user && auth_hash.try(:[], :provider) == 'facebook'
      redirect_to settings_path, notice: 'facebook done!!!' if current_user.add_auth(auth_hash)
    end
  end

  def add_auth_for_twitter
    if current_user && auth_hash.try(:[], :provider) == 'twitter'
      redirect_to settings_path, notice: 'twitter done!!!' if current_user.add_auth(auth_hash)
    end
  end

  def save_signup_history(member_id)
    SignupHistory.create(
      member_id: member_id,
      ip: request.ip,
      accept_language: request.headers["Accept-Language"],
      ua: request.headers["User-Agent"]
    )
  end

end
