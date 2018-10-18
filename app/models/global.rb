class Global
  ZERO = '0.0'.to_d
  NOTHING_ARRAY = YAML::dump([])
  LIMIT = 80

  class << self
    def channel
      "market-global"
    end

    def trigger(event, data)
      Pusher.trigger_async(channel, event, data)
    end

    def daemon_statuses
      Rails.cache.fetch('exchangepro:daemons:statuses', expires_in: 3.minute) do
        Daemons::Rails::Monitoring.statuses
      end
    end
    def coincheck_price currency
      url_last = "https://coincheck.com/api/rate/#{currency}_jpy"
      response = HTTParty.get(url_last)
      response.parsed_response["rate"].to_i
    end
  end

  def initialize(currency)
    @currency = currency
  end

  def channel
    "market-#{@currency}-global"
  end

  attr_accessor :currency

  def self.[](market)
    if market.is_a? Market
      self.new(market.id)
    else
      self.new(market)
    end
  end

  def key(key, interval=5)
    seconds  = Time.now.to_i
    time_key = seconds - (seconds % interval)
    "exchangepro:#{@currency}:#{key}:#{time_key}"
  end

  def asks
    Rails.cache.read("exchangepro:#{currency}:depth:asks") || []
  end

  def bids
    Rails.cache.read("exchangepro:#{currency}:depth:bids") || []
  end

  def default_ticker
    {low: ZERO, high: ZERO, last: ZERO, volume: ZERO}
  end

  def ticker
    ticker           = Rails.cache.read("exchangepro:#{currency}:ticker") || default_ticker
    open             = Rails.cache.read("exchangepro:#{currency}:ticker:open") || ticker[:last]
    best_buy_price   = bids.first && bids.first[0] || ZERO
    best_sell_price  = asks.first && asks.first[0] || ZERO

    ticker.merge({
      open: open,
      volume: h24_volume,
      sell: best_sell_price,
      buy: best_buy_price,
      at: at
    })
  end

  def h24_volume
    Rails.cache.fetch key('h24_volume', 5), expires_in: 24.hours do
      Trade.with_currency(currency).h24.sum(:volume) || ZERO
    end
  end

  def trades
    Rails.cache.read("exchangepro:#{currency}:trades") || []
  end

  # setting price is included fee
  def last_buy
    price_setting = CoinTradePrice.find_by_market("#{currency}","TradeBid")
    return if price_setting.nil?

    if price_setting.activate_price
      last_buy = {:price => price_setting.price}
    elsif !trades.blank?
      last_buy = Rails.cache.read("exchangepro:#{currency}:trades").select { |trade| trade[:type] == "buy" }
      last_buy = optimize_price(last_buy, price_setting.fee)
    end
    Rails.cache.write("exchangepro:#{currency}:last_buy", last_buy)
    last_buy
  end

  # setting price is included fee
  def last_sell
    price_setting = CoinTradePrice.find_by_market("#{currency}","TradeAsk")
    return if price_setting.nil?

    if price_setting.activate_price
      last_sell = {:price => price_setting.price}
    elsif !trades.blank?
      last_sell = Rails.cache.read("exchangepro:#{currency}:trades").select { |trade| trade[:type] == "sell" }
      last_sell = optimize_price(last_sell, price_setting.fee)
    end

    Rails.cache.write("exchangepro:#{currency}:last_sell", last_sell)
    last_sell
  end

  #included fee price from bit-station exchange, not setting price
  def optimize_price(last_buy_sell, fee)
    if last_buy_sell.first
      price_precision = Market.find_by_id(@currency)[:price_precision]
      pow = (10 ** price_precision).to_d
      last_price = ((last_buy_sell.first[:price].to_d * (1 - fee / 100)) * pow).ceil / pow
      last_buy_sell = {:price => last_price}
    end
    last_buy_sell
  end

  def trigger_orderbook
    data = {asks: asks, bids: bids}
    Pusher.trigger_async(channel, "update", data)
  end

  def trigger_trades(trades)
    Pusher.trigger_async(channel, "trades", trades: trades)
  end

  def trigger_ticker
    data = ticker
    Pusher.trigger_async(channel, "ticker", data)
  end

  def trigger_last_buy
    Pusher.trigger_async(channel, "last_buy", last_buy: last_buy)
  end

  def trigger_last_sell
    Pusher.trigger_async(channel, "last_sell", last_sell: last_sell)
  end

  def at
    @at ||= DateTime.now.to_i
  end
end
