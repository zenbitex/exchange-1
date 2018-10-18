class ActivationEmailsController < ApplicationController
  include Concerns::TokenManagement

  before_action :token_required!, only: [:edit]

  def edit
    if @token.confirm!
      old_email = Member.find(@token.member_id).email
      Member.where(email: old_email).update_all(email: @token.new_email)
      Identity.where(email: old_email).update_all(email: @token.new_email)
      Sendcoin.where(user_id_destination: @token.member_id).update_all(email: @token.new_email)
      reset_session rescue nil
      session[:member_id] = @token.member_id
      save_session_key @token.member_id, cookies['_exchangepro_session']
      save_signup_history @token.member_id
      MemberMailer.notify_signin(@token.member_id).deliver if Member.find(@token.member_id).activated?
      redirect_to settings_path, notice: t('.notice')
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
