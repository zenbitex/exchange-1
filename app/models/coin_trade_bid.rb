class CoinTradeBid < CoinTrade
  validate :examine_price, on: :create, unless: 'currency == "tao"'
  validate :examine_price_tao, on: :create, if: 'currency == "tao"'
  validate :examine_account_balance, on: :create
  after_create :executed
  after_create :special_finish!, if: 'currency == "tao"'
  after_create :order_to_kraken, unless: 'currency == "tao"'

  # send buy order to Kraken
  def order_to_kraken
    kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
    origin_price = cal_origin_price
    Process.fork do
      txid = kraken.buy_sell(amount, origin_price, "buy", currency+payment_type, "+3600")
      MyLog.kraken("#{Process.pid}")
      if txid.is_a?(Hash)
        self.txid = txid[:error]
      else
        self.txid = txid
      end
      self.save
      self.order!
    end
  end

  # send coin from karaken to server
  def request_withdraw
    kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
    withdraw_txid = kraken.withdraw(currency, ENV['KEY_WITHDRAW'], amount)
    if !withdraw_txid.nil? && !withdraw_txid.empty?
      self.withdraw_txid = withdraw_txid
      self.save
      self.withdraw!
    end
    # MyLog.kraken("WITHDRAW: #{currency} #{payment_type} -- #{amount}")
  end


  def executed
    origin_price = cal_origin_price
    total = currency_around(price * amount, payment_type)

    # plus coin
    currency_balance = member.accounts.find_by_currency(currency.value)
    currency_balance.plus_funds amount, reason: Account::COIN_TRADE_BID, ref: self
    # sub jpy
    payment_balance = member.accounts.find_by_currency(payment_type.value)
    payment_balance.sub_funds total, reason: Account::COIN_TRADE_BID, ref: self

    self.origin_price = cal_origin_price
    self.total        = total
    self.fee          = (price - origin_price) * amount
    self.save
  end

  def examine_price
    buy_price = trust_buy_price
    # pry
    if buy_price != price.to_f
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade_bid.suspect_price') }
    end
  end

  def examine_price_tao
    buy_price = trust_price_tao
    if buy_price != price.to_f
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade_bid.suspect_price') }
    end
  end

  def examine_account_balance
    total = currency_around(price * amount, payment_type)
    if total.nil? || total > member_balance
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade.user_insufficient', {currency: payment_type.upcase}) }
    end
  end

  private

  def member_balance
    member.accounts.find_by_currency(payment_type.value).balance
  end

  def cal_origin_price
    fee = get_setting_price('TradeBid').fee
    origin_price = price * (1 - fee/100.to_f)
    price_around(origin_price, currency+payment_type)
  end

  # trust price on server
  def trust_price_tao
    setting_price = get_setting_price('TradeBid')
    if setting_price.activate_price
      setting_price.price
    else
      global = Global.new("#{currency}#{payment_type}")
      return 0 if global.last_buy.nil?
      return 0 if global.last_buy[:price].nil?
      global.last_buy[:price]
    end
  end

  # trust price on server
  def trust_buy_price
    setting_price = get_setting_price('TradeBid')
    if setting_price.activate_price
      setting_price.price
    else
      Rails.cache.read("kraken-price-#{currency}#{payment_type}")[:buy_order_price]
    end
  end
end
