class IdentitiesController < ApplicationController
  #before_filter :auth_anybody!, only: :new
  before_action :confirm_password, only: [:update_email]

  def new
    if current_user
      redirect_to accounts_path
      return
    end
    @identity = env['omniauth.identity'] || Identity.new
    @referrer_code = params[:code_referrer]
  end

  def edit
    @identity = current_user.identity
  end

  def update
    @identity = current_user.identity

    unless @identity.authenticate(params[:identity][:old_password])
      redirect_to edit_identity_path, alert: t('.auth-error') and return
    end

    if @identity.authenticate(params[:identity][:password])
      redirect_to edit_identity_path, alert: t('.auth-same') and return
    end

    if @identity.update_attributes(identity_params)
      current_user.send_password_changed_notification
      clear_all_sessions current_user.id
      reset_session
      redirect_to signin_path, notice: t('.notice')
    else
      render :edit
    end
  end

  def confirm_password
  end

  def verify_password
    @identity = current_user.identity
    result = @identity.authenticate(params[:identity][:password])
    if result
      redirect_to update_email_path
    else
      redirect_to :back, :alert => t('.password_not_correct')
    end
  end

  def update_email
  end

  def change_email
    params[:email] = params[:email].normalize_zen_han
    check_email_exits = Member.where(:email => params[:email]).exists?
    if check_email_exits
      redirect_to :back, alert: t('header.email_exit')
    else
      if !params[:email].nil? and Identity.valid_email?params[:email]
        token = current_user.send_mail_activation
        token.new_email = params[:email]
        token.save
        session[:active_mail] = token
        TokenMailer.edit_email(params[:email], token[:id]).deliver
        clear_all_sessions current_user.id
        reset_session
        redirect_to signin_path, :notice => t('header.send_mail')
      else
        redirect_to :back, :alert => t('header.error_email')
      end
    end
  end

  private
    def identity_params
      params.required(:identity).permit(:password, :password_confirmation)
    end
end
