class SecuritiesController < ApplicationController
  before_action :auth_member!, only: [:edit, :update]
  before_action :two_factor_activated?, only: :update
  before_action :get_settings, only: :update

  def edit
    @security = current_user.security || current_user.create_securities
    @signup_histories = current_user.signup_histories.order("created_at desc").page(params[:page]).per(40)
  end

  def update
    @security = current_user.security

    notice = if update_setting!
      t('.successfull')
    else
      t('.failed')
    end

    redirect_to security_path, notice: notice
  end

  private

  def update_setting!
    @two_factors_setting.each do |key, value|
      @security.two_factor[key] = value
    end

    @email_setting.each do |key, value|
      @security.send_email[key] = value
    end

    @security.save
  end

  def get_settings
    @two_factors_setting = {}
    @email_setting = {}

    @two_factors_setting["Withdraw"] = true? params["security"]["two-factor-Withdraw"]
    @two_factors_setting["Login"] = true? params["security"]["two-factor-Login"]
    @email_setting["Withdraw"] = true? params["security"]["send-email-Withdraw"]
    @email_setting["Login"] = true? params["security"]["send-email-Login"]
  end

  def two_factor_activated?
    if (true?(params["security"]["two-factor-Withdraw"]) ||
        true?(params["security"]["two-factor-Login"])) &&
        !current_user.two_factors.by_type("app").activated
      redirect_to security_path, alert: t('.update_failed')
    end
  end

  def true? obj
    obj.to_s == "1"
  end
end
