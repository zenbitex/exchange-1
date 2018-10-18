require 'digest'
module Private
  class BuyCoinController < BaseController
    def show
      @fee = FeeTrade.find_by(fee_type: "CreditCard").amount.to_f;
      markets = ["btcjpy", "xrpjpy"]
      @prices = {}
      @price_setup = {}
      for market in markets 
        @prices[market] = price market
      end
      @history_buy = BuyCoin.where(member_id: current_user.id, status: 1).order("created_at desc").page(params[:page]).per(15) 
    end

    def price market
      return 0 if market.nil?

      # price buy sell from server
      # price_setup = CreditSetupPrice.find_by(market: market, enable: 1)
      # if price_setup && price_setup.price.to_f > 0
      #   price_market = price_setup.price.to_f
      #   @price_setup = {} if @price_setup.nil?
      #   @price_setup[market] = true
      # else 
      #   code_market = Market.find(market).code
      #   orders = Order.active.where(type: "OrderAsk", currency: code_market).order('price ASC')
      #   if orders.count > 0
      #     price_market = orders[0].price
      #   else 
      #     price_market = coin_price market
      #   end 
      # end 
      # 
      price_setup = CreditSetupPrice.find_by(market: market, enable: 1)
      if price_setup && price_setup.price.to_f > 0
        price_market = price_setup.price.to_f
        @price_setup = {} if @price_setup.nil?
        @price_setup[market] = true
      else 
        chanel = 'kraken-price'
        data =  Rails.cache.read chanel + "-#{market}"
        if data.nil? || data[:buy_order_price].nil?
          price_market = coin_price market
        else 
          price_market = data[:buy_order_price]
        end 
      end
      @fee = FeeTrade.find_by(fee_type: "CreditCard").amount.to_f
      price_market = (price_market.to_f / (1 - @fee)).round(2)
    end

    def create_id id
      id_buy = Time.now.to_i.to_s + id.to_s
      id_buy += rand(0...1000).to_s
      Digest::SHA256.hexdigest(id_buy)
    end

    def save_data
      market = params[:market]
      currency = get_currency market
      coin_name = get_coin market
      sum_amount = Currency.all.map(&:summary)
      admin_balance = sum_amount.find{|v| v[:name] == coin_name}
      admin_amount = admin_balance[:sum].to_f
      price_current = price(market)
      money = params[:money].to_f
      amount = money/price_current

      if amount > admin_amount
        if admin_amount == 0
          render :json => {message: t("buy_coin.amount_zero")}
        else 
          render :json => {message: t("buy_coin.max_amount", {amount: " #{admin_amount}#{coin_name} "})}
        end
        return
      end

      @fee = FeeTrade.find_by(fee_type: "CreditCard").amount.to_f;
      buy_coin = BuyCoin.new(market: market, member_id: current_user.id, price: price_current, money: params[:money], status: 0, fee: @fee)
      if buy_coin.save
        id_buy = create_id buy_coin.id
        if buy_coin.update_attribute(:id_buy, id_buy)
          render :json => {id_buy: id_buy}
          return 
        end 
      end
      render :json => {message: t("buy_coin.server_busy")}
    end

    def get_currency market
      case market
        when "btcjpy"
          currency = 2
        when "xrpjpy"
          currency = 5
      end
    end

    def get_coin market
      case market
        when "btcjpy"
          coin = "BTC"
        when "xrpjpy"
          coin = "XRP"
      end
    end

    def get_round market
      case market
        when "btcjpy"
          round = 6
        when "xrpjpy"
          round = 4
      end
    end

    def create
      begin
        id_buy = params[:id_buy]
        order = BuyCoin.find_by(id_buy: id_buy)
        time = Time.now.to_i
        if order.nil? || time - order.updated_at.to_i > 120
          render :json => {status: 401, message:  t("buy_coin.order_fail")}
          return
        end
        money = order.money.to_i
        customer = Stripe::Customer.create(
          :source  => params[:token_id],
        )
        charge = Stripe::Charge.create(
          :customer    => customer.id,
          :amount      => money,
          :description => "Buy coin (id buy: #{id_buy})",
          :currency    => 'jpy',
        )
        if charge && charge.status  == "succeeded"
          market = order.market
          price = order.price
          round = get_round market
          amount = (money / price).round(round)
          order.update_attributes(status: 1, amount: amount)
          currency = get_currency market
          user_account = current_user.accounts.find_by(currency: currency)
          admin_balance = Account.find_by(:member_id => 1,:currency => currency)
          admin_balance.lock!.sub_funds amount, reason: Account::CREDIT_CARD, ref: nil
          user_account.lock!.plus_funds amount, reason: Account::CREDIT_CARD, ref: nil
          coin = get_coin market
          render :json => {message: t("buy_coin.paymement_finish"), coin: coin, price: order.price, amount: order.amount, time: order.created_at}
        else 
          order.update_attribute(:status, -1)
          render :json => {status: 401, message: t("buy_coin.paymement_error")}
        end

      rescue => error
        flash[:error] = error.message
        render :json => {status: 401, message: t("buy_coin.paymement_error")}
      end
    end
  end
end
