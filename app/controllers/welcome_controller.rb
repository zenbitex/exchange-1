class WelcomeController < ApplicationController
  def index
    if current_user
      redirect_to  accounts_path 
      return
    end

    url_last = 'https://coincheck.com/api/rate/btc_jpy'
    response = HTTParty.get(url_last)
    @price = response.parsed_response["rate"].to_i

    url_boarding = 'https://coincheck.com/api/order_books'
    response = HTTParty.get(url_boarding)
    @sell = response.parsed_response["asks"][0][0].to_i
    @buy = response.parsed_response["bids"][0][0].to_i

    @identity = env['omniauth.ide5ntity'] || Identity.new
    # market = Market.find("btcjpy")
    # price = market.ticker
    # @sell = price[:sell].to_f
    # @buy = price[:buy].to_f
    # @price = price[:last].to_f
    if current_user
      @btc_balance = current_user.accounts.find_by_currency(2).balance.to_f
      @jpy_balance = current_user.accounts.find_by_currency(1).balance.to_f
    end

    case locale.to_s
      when "en"
        @facebook_language = "en_US"
        @twitter_language = "en"
      when "zh-CN"
        @facebook_language = "zh_CN"
        @twitter_language = "zh-cn"
      else
        @facebook_language = "ja_JP"
        @twitter_language = "ja"
    end
  end

  def payment_address
  end

  def term_of_use
  end
  def company_about
  end
  def success_message
  end

  def about
  end

  def faq
  end

end
