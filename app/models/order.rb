class Order < ActiveRecord::Base
  extend Enumerize

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true
  ZERO = 0.to_d
  ORD_TYPES = %w(market limit)
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger #is called after a record has been created, updated, or destroyed.
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
    if: "ord_type == 'limit'"
  validate :market_order_validations, if: "ord_type == 'market'"
  validate :limit_amount, :on => :create
  # validate :limit_price, :on => :create

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market kind price state state_text volume origin_volume trades_count)

  belongs_to :member
  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  def funds_used
    origin_locked - locked
  end

  def fee
    config[kind.to_sym]["fee"]
  end

  def config
    @config ||= Market.find(currency)
  end

  def fixed
    config[kind.to_sym]["fixed"]
  end

  #fee bid & fee ask is same currency type
  def fee_fixed
    config[__method__]
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('order', json)
  end

  def strike(trade)
    raise "Cannot strike on cancelled or done order. id: #{id}, state: #{state}" unless state == Order::WAIT

    #sell
    if kind == "ask"
      currency_id = Currency.code_to_id(expect_account.currency)
      admin_account = Member.find_by_id(1).accounts.find_by_currency(currency_id)
      real_sub, add = get_account_changes trade
      real_fee = (add.to_f * fee).round(fee_fixed)
      # real_fee = (real_fee * 10 ** fee_fixed.to_f).ceil / (10 ** fee_fixed.to_f)
      MyLog.kraken("SELL")
      real_add = add - real_fee
      if hold_account.locked < real_sub
        real_sub = hold_account.locked
      end
      hold_account.unlock_and_sub_funds \
        real_sub, locked: real_sub,
        reason: Account::STRIKE_SUB, ref: trade

      expect_account.plus_funds \
        real_add, fee: real_fee,
        reason: Account::STRIKE_ADD, ref: trade

      if real_fee > 0
        admin_account.plus_funds \
          real_fee,
          reason: Account::STRIKE_FEE, ref: trade
      end

      self.volume         -= trade.volume
      self.locked         -= real_sub
      self.funds_received += add
      self.trades_count   += 1

      if volume.zero?
        self.state = Order::DONE
        MyLog.kraken("unlock_funds: #{locked}")
        unlock_amount = locked < ZERO ? ZERO : locked
        # unlock not used funds
        hold_account.unlock_funds unlock_amount,
          reason: Account::ORDER_FULLFILLED, ref: trade unless unlock_amount.zero?
      elsif ord_type == 'market' && locked.zero?
        # partially filled market order has run out its locked fund
        self.state = Order::CANCEL
      end

      # end
      trade.update!(:fee => real_fee) if fee > 0
      self.save!
    else
      #BUY
      currency_id = Currency.code_to_id(hold_account.currency)
      admin_account = Member.find_by_id(1).accounts.find_by_currency(currency_id)
      real_sub, real_add = get_account_changes trade
      real_fee = (real_sub.to_f * fee.to_f).round(fee_fixed)
      # real_fee = (real_fee * 10 ** fee_fixed.to_f).ceil / (10 ** fee_fixed.to_f)
      real_sub = real_sub + real_fee

      #sub fiat
      if hold_account.locked < real_sub
        real_sub = hold_account.locked
      end
      hold_account.unlock_and_sub_funds \
        real_sub, locked: real_sub, fee: real_fee,
        reason: Account::STRIKE_SUB, ref: trade

      #add coin
      expect_account.plus_funds \
        real_add,
        reason: Account::STRIKE_ADD, ref: trade

      if real_fee > 0
        admin_account.plus_funds \
          real_fee,
          reason: Account::STRIKE_FEE, ref: trade
      end

      self.volume         -= trade.volume
      self.locked         -= real_sub
      self.funds_received += real_add
      self.trades_count   += 1

      if volume.zero?
        self.state = Order::DONE
        # unlock not used funds
        MyLog.kraken("unlock_funds: #{locked}")
        unlock_amount = locked < ZERO ? ZERO : locked
        hold_account.unlock_funds unlock_amount,
          reason: Account::ORDER_FULLFILLED, ref: trade unless unlock_amount.zero?
      elsif ord_type == 'market' && locked.zero?
        # partially filled market order has run out its locked fund
        self.state = Order::CANCEL
      end

      trade.update!(:bid_fee => real_fee) if fee > 0
      self.save!
    end
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def market
    currency
  end

  def to_matching_attributes
    { id: id,
      market: market,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      locked: locked,
      timestamp: created_at.to_i }
  end

  def fix_number_precision
    self.price = config.fix_number_precision(:bid, price.to_d) if price

    if volume
      self.volume = config.fix_number_precision(:ask, volume.to_d)
      self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
    end
  end

  private

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  FUSE = '0.9'.to_d
  def estimate_required_funds(price_levels)
    required_funds = Account::ZERO
    expected_volume = volume

    start_from, _ = price_levels.first
    filled_at     = start_from

    until expected_volume.zero? || price_levels.empty?
      level_price, level_volume = price_levels.shift
      filled_at = level_price

      v = [expected_volume, level_volume].min
      required_funds += yield level_price, v
      expected_volume -= v
    end

    raise "Market is not deep enough" unless expected_volume.zero?
    raise "Volume too large" if (filled_at-start_from).abs/start_from > FUSE

    required_funds
  end

  def limit_amount
    if origin_volume < Market.find(market)[:limit_amount].to_d
      errors.add(:amount, I18n.t("private.markets.show.amount_min", {min: Market.find(market)[:limit_amount], currency: ask.upcase}))
    end
  end

  def limit_price
    low, high = price_range
    return if ask == "tao"
    return if low.zero? && high.zero?
    return if !errors.messages[:amount].nil?

    if price < low
      errors.add(:amount,  I18n.t("private.markets.show.price_too_low"))
    end
    if price > high
      errors.add(:amount, I18n.t("private.markets.show.price_too_high"))
    end
  end

  def price_range
    limit = 0.5
    global = Global.new(market)
    last_sell = global.trades.select{ |t| t[:type] == "sell" }
    last_sell = last_sell.blank? ? 0 : last_sell.first[:price].to_f
    last_buy = global.trades.select{ |t| t[:type] == "buy" }
    last_buy = pivot_price = last_buy.blank? ? 0 : last_buy.first[:price].to_f
    pivot_price = last_sell if pivot_price.zero?
    return pivot_price*limit , pivot_price*(1+limit)
  end
end
