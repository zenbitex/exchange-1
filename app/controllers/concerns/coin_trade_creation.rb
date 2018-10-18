module Concerns
  module CoinTradeCreation
    extend ActiveSupport::Concern

    private

    def init_price_from_cache
      if @market[:base_unit] == 'tao'
        last_price  = Rails.cache.read "exchangepro:#{@market[:id]}:last_buy"
        @price_buy  = (last_price.nil? || last_price.empty?) ? 0: last_price[:price]
        last_price  = Rails.cache.read "exchangepro:#{@market[:id]}:last_sell"
        @price_sell = (last_price.nil? || last_price.empty?) ? 0: last_price[:price]
      else
        price = Rails.cache.read "kraken-price-#{@market[:id]}"
        @price_buy  = price.nil? ? 0 : price[:buy_order_price]
        @price_sell = price.nil? ? 0 : price[:sell_order_price]
      end
    end

    def coin_trade_params(order)
      params[order][:member_id] = current_user.id
      params.require(order).permit(:currency, :payment_type, :amount, :member_id, :price)
    end

    def sell_tao?
      coin_trade_params(:coin_sell)[:currency] == 'tao'
    end

  end
end
