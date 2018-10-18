class AccountsController < ApplicationController
  before_action :auth_member!, :create_account
  before_action :bonus_affiliate
  def index
    create_account
    @markets = Market.all
    @account_versions = current_user.account_versions.page(params[:page]).per 10
    @coincheck_price = {
      "btc" => 0,
      "etc" => 0,
      "eth" => 0,
      "xrp" => 0,
      "bch" => 0,
      "kbr" => 0
    }
    # binding.pry
    @coincheck_price = Rails.cache.read("coincheck-price") || @coincheck_price
    @total_rate = 1
    @base_unit = "円"
    if I18n.locale.to_s != "ja"
      @total_rate = 112
      @base_unit = "$"
    end

    #total assets
    @total = 0
    current_user.accounts.each do |ac|
      @total += (ac.balance + ac.locked) * @coincheck_price[ac.currency].to_f * @total_rate
    end

    #pie_chart
    @series_data = []
    per_res = 100
    current_user.accounts.each do |ac, index|
      asset = (ac.balance + ac.locked) * @coincheck_price[ac.currency].to_f * @total_rate
      percentage = (asset / @total).round(3)
      per_res = per_res - percentage

      if index == current_user.accounts.size - 1
        percentage = per_res
        if per_res == 100
          @series_data = []
          break
        end
      end
      @series_data << {name: ac.currency, y: percentage.to_f}
    end
    gon.jbuilder
  end

  def create_account
    currency_ids = Currency.ids
    current_acc  = current_user.accounts.pluck("currency")
    diff = currency_ids - current_acc
    diff.each do |id|
      current_user.get_account(Currency.id_to_code(id))
    end
  end
end
