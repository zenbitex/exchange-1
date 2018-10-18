module Admin
  class CoinTradePricesController < BaseController
    before_action :create_record
    def index
      @prices = CoinTradePrice.all
    end

    def edit
      @price = CoinTradePrice.find(params[:id])
    end

    def update
      @price = CoinTradePrice.find(params[:id])
      if @price.update_attributes(coin_trade_price_params)
        redirect_to admin_coin_trade_prices_path, notice: "edit successful"
      else
        render :edit
      end
    end

    def create_record
      markets = Market.all
      markets.each do |mk|
        next if CoinTradePrice.find_by(:currency => Currency.find_by_code(mk[:base_unit]).id, :payment_type =>  Currency.find_by_code(mk[:quote_unit]).id)
        CoinTradePrice.create(:currency => mk[:base_unit], :payment_type => mk[:quote_unit], :activate_price => false, :trade_type => 'TradeAsk', :fee => 5)
        CoinTradePrice.create(:currency => mk[:base_unit], :payment_type => mk[:quote_unit], :activate_price => false, :trade_type => 'TradeBid', :fee => 5)
      end
    end

    def activate_admin_price
      record = CoinTradePrice.find(params[:format])
      if record.price
        if params[:enable]
          record.update(:activate_price => true)
          redirect_to admin_coin_trade_prices_path, notice: "enable admin price"
        else
          record.update(:activate_price => false)
          redirect_to admin_coin_trade_prices_path, alert: "disable admin price"
        end
      else
        redirect_to admin_coin_trade_prices_path, alert: "have no price"
      end
    end

    private
    def coin_trade_price_params
      params.require(:coin_trade_price).permit(:price, :fee)
    end
  end
end
