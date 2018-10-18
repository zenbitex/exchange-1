module Private
  class CoinTradesController < BaseController
    include Concerns::CoinTradeCreation
    helper BuyCoinHelper

    def index
      # @currencie_coins = Currency.where(coin: true)
      # @currencies      = Currency.all
      @history         = current_user.coin_trades.order("created_at desc").page(params[:page]).per(10)
      @coin_trade      = CoinTradeAsk.new
      @market          = current_market
      @markets         = Market.all.select { |e|  e[:base_unit] != "bch"}
      # @market_groups   = @markets.map(&:quote_unit).uniq

      init_price_from_cache
      @trade_type      = @market[:base_unit]
      @payment_type    = @market[:quote_unit]
      @step            = Currency.find_by_code(@trade_type)[:step]
      @min             = current_market.limit_coin_trade
      @total_precision = Currency.find_by_code(@payment_type)[:precision]
      @price_precision = @market[:price_precision]
      @amount_precision= Currency.find_by_code(@trade_type)[:precision]
      @trades          = @market.trades
      @threshold       = Currency.find_by_code(@payment_type)[:max_coin_trade]

      gon.jbuilder
    end

    # Sell
    def sell_create
      if sell_tao?
        redirect_to coin_trades_path, alert: t('.not_sell_tao')
        return
      end
      @coin_trade = CoinTradeAsk.new coin_trade_params(:coin_sell)
      if @coin_trade.save
        redirect_to coin_trades_path, notice: t('.successful')
      else
        redirect_to coin_trades_path, alert: @coin_trade.errors.full_messages.join(', ')
      end
    end

    # Buy
    def buy_create
      @coin_trade = CoinTradeBid.new coin_trade_params(:coin_buy)
      if @coin_trade.save
        redirect_to coin_trades_path, notice: t('.successful')
      else
        redirect_to coin_trades_path, alert: @coin_trade.errors.full_messages.join(', ')
      end
    end

    def load_history
      page_num = params["page"].nil? ? 1 : params["page"].to_i
      @histories = current_user.coin_trades.order("created_at desc").page(page_num).per(10)
      @histories.map { |e|
        e.trade_type = case e.type
                when "CoinTradeBid"
                  t('.buy')
                when "CoinTradeAsk"
                  t('.sell')
                end
        e
      }
      render json: @histories
    end
  end
end
