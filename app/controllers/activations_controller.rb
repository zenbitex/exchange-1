class ActivationsController < ApplicationController
  include Concerns::TokenManagement

  before_action :auth_member!,    only: :new
  before_action :verified?,       only: :new
  before_action :token_required!, only: :edit

  def new
    current_user.send_activation
    redirect_to settings_path
  end

  def edit
    @token.confirm!
    if current_user
      gen_address
      redirect_to settings_path, notice: t('.notice')
    else
      redirect_to signin_path, notice: t('.notice')
    end
  end

  def gen_address
    current_user.accounts.each do |account|
      next if not account.currency_obj.coin?

      if account.payment_addresses.blank?
        account.payment_addresses.create(currency: account.currency)
      else
        address = account.payment_addresses.last
        address.gen_address if address.address.blank?
      end
    end
  end


  private

  def verified?
    if current_user.activated?
      redirect_to settings_path, notice: t('.verified')
    end
  end

end
