class TwoFactorsAccessController < ApplicationController
  before_action :auth_pass!
  def index

  end

  def verify
    member = Member.enabled.where(id: session[:member_id]).first
    google_auth = member.app_two_factor
    google_auth.assign_attributes(params_otp)
    if !google_auth.verify?
      redirect_to two_factors_access_index_path, alert: I18n.t('two_factors_access.index.otp_wrong')
      return
    end

    clear_failed_logins
    session[:two_factors] = true
    save_session_key member.id, cookies['_exchangepro_session'] #Save cache.
    save_signup_history member.id
    if session[:active_email].nil?
      MemberMailer.notify_signin(member.id).deliver if member.activated?
    end
    redirect_back_or_settings_page
  end

  private
  def save_signup_history(member_id)
    SignupHistory.create(
      member_id: member_id,
      ip: request.ip,
      accept_language: request.headers["Accept-Language"],
      ua: request.headers["User-Agent"]
    )
  end

  def clear_failed_logins
    Rails.cache.delete failed_login_key
  end

  def failed_login_key
    "exchangepro:session:#{request.ip}:failed_logins"
  end

  def params_otp
    params.permit(:otp)
  end
end
