module Authentications
  class EmailsController < ApplicationController
    before_action :auth_member!
    # before_action :check_email_present
    before_action :check_password, only: [:edit, :update]
    before_action :login_with_social_network, only: [:edit, :update]
    
    def new
      flash.now[:info] = t('.setup_email')
    end
    def create
      if current_user.update_attributes(email: params[:email][:address])
        redirect_to settings_path
      else
        flash.now[:alert] = current_user.errors.full_messages.join(',')
        render :new
      end
    end
    def edit
      @email = Member.new
    end
    def update
      @email = Member.new(params[:email])
    end
    private
    def check_email_present
      redirect_to settings_path if current_user.email.present?
    end
    def check_password
      redirect_to confirm_password_path if current_user.email.present?
    end

    private
    def login_with_social_network
      redirect_to '/404.html' if !current_user.authentications.identity?
    end
    
  end
end
