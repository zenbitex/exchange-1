module Private
  class MarketsController < BaseController
    skip_before_action :auth_member!, only: [:show]
    before_action :visible_market?
    # before_action :is_staging?
    after_action :set_default_market

    layout false

    def show
      @bid = params[:bid]
      @ask = params[:ask]

      @market        = current_market
      @markets       = Market.all.sort
      @market_groups = @markets.map(&:quote_unit).uniq
      @accounts      = load_accounts

      @bids   = @market.bids
      @asks   = @market.asks
      @trades = @market.trades

      @api_url = "http://#{ENV["URL_HOST"]}/api/v2"
      if Rails.env == "production"
        @api_url = "https://#{ENV["URL_HOST"]}/api/v2"
      end


      # default to limit order
      @order_bid = OrderBid.new ord_type: 'limit'
      @order_ask = OrderAsk.new ord_type: 'limit'

      set_member_data if current_user
      gon.jbuilder
    end

    private

    def load_accounts
      accounts = []
      return accounts unless @current_user
      accounts << @current_user.accounts.by_currencies(Currency.find_by_code(@market.base_unit).id).first
      accounts << @current_user.accounts.by_currencies(Currency.find_by_code(@market.quote_unit).id).first
    end

    def visible_market?
      redirect_to market_path(Market.first) if not current_market.visible?
    end

    def set_default_market
      cookies[:market_id] = @market.id
    end

    def set_member_data
      @member = current_user
      @orders_wait = @member.orders.with_currency(@market).with_state(:wait)
      @trades_done = Trade.for_member(@market.id, current_user, limit: 100, order: 'id desc')
    end

    def is_staging?
      redirect_to root_path if Rails.env == 'production'
    end

  end
end
