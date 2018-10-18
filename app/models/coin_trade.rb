class CoinTrade < ActiveRecord::Base
  extend Enumerize
  include AASM

  belongs_to :member
  enumerize :currency, in: Currency.enumerize
  enumerize :payment_type, in: Currency.enumerize

  validates_presence_of :currency, :payment_type, :amount, :price
  # validates_numericality_of :amount, greater_than: 0
  validate :greater_than_limit_amount, on: :create
  validates_numericality_of :price, greater_than: 0
  validates_numericality_of :member_id, greater_than: 0

  aasm do
    state :submit, initial: true
    state :waiting    # txid exits / waiting order to kraken
    state :transacted # order successful to kraken
    state :withdrawing
    state :completed

    # ordering buy_sell to kraken
    event :order do
      transitions from: :submit, to: :waiting
    end

    # order on kraken completed
    event :order_done, :after => :request_withdraw do
      transitions from: :waiting, to: :transacted
    end

    # withdraw from kraken to bit-station
    event :withdraw do
      transitions form: :transacted, to: :withdrawing
    end

    event :finish do
      transitions from: :withdrawing, to: :completed
    end

    event :special_finish do
      transitions from: :submit, to: :completed
    end
  end

  private
  def greater_than_limit_amount
    market = Market.find("#{currency}#{payment_type}")
    min = market.limit_coin_trade
    if amount < min
      errors.add :base, -> { I18n.t('activerecord.errors.models.coin_trade.min_amount',{min: min, currency: market.base_unit.upcase}) }
    end
  end

  # belong to currency itself
  def currency_around(total, currency)
    total.round(Currency.precision(currency))
  end

  # belong to market
  def price_around(price, pair)
    price.round(Market.price_precision(pair))
  end

  # setting price included fee
  def get_setting_price(type)
    CoinTradePrice.find_by(:currency => currency.value, :payment_type => payment_type.value, :trade_type => type)
  end
end
