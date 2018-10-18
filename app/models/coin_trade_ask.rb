class CoinTradeAsk < CoinTrade
  validate :currency, exclusion: { in: %w(tao), message: "%{value} not for sell."}
  validate :examine_price, on: :create
  validate :examine_account_balance, on: :create
  after_create :executed
  after_create :order_to_kraken

  # send sell order to Kraken
  def order_to_kraken
    kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
    origin_price = cal_origin_price
    Process.fork do
      txid = kraken.buy_sell(amount, origin_price, "sell", currency+payment_type, "+3600")
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

  # send coin from karaken to bit-station
  def request_withdraw
    kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
    withdraw_txid = kraken.withdraw(payment_type, ENV['KEY_WITHDRAW'], amount)
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

    # sub coin
    currency_balance = member.accounts.find_by_currency(currency.value)
    currency_balance.sub_funds amount, reason: Account::COIN_TRADE_ASK, ref: self
    # plus jpy
    payment_balance = member.accounts.find_by_currency(payment_type.value)
    payment_balance.plus_funds total, reason: Account::COIN_TRADE_ASK, ref: self

    self.origin_price = cal_origin_price
    self.total        = total
    self.fee          = (origin_price - price) * amount
    self.save
  end

  def examine_price
    sell_price = trust_sell_price
    if sell_price != price.to_f
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade_bid.suspect_price') }
    end
  end

  def examine_account_balance
    if amount > member_balance
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade.user_insufficient', {currency: currency.upcase}) }
    end
  end

  private

  def member_balance
    member.accounts.find_by_currency(currency.value).balance
  end

  def cal_origin_price
    fee = get_setting_price('TradeAsk').fee
    origin_price = price / (1 - fee/100.to_f)
    price_around(origin_price, currency+payment_type)
  end

  # trust price on server
  def trust_sell_price
    setting_price = get_setting_price('TradeAsk')
    if setting_price.activate_price
      setting_price.price
    else
      Rails.cache.read("kraken-price-#{currency}#{payment_type}")[:sell_order_price]
    end
  end
end
