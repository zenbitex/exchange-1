class AccountVersion < ActiveRecord::Base
  include Currencible

  HISTORY = [Account::STRIKE_ADD, Account::STRIKE_SUB, Account::STRIKE_FEE, Account::DEPOSIT, Account::WITHDRAW, Account::FIX]

  enumerize :fun, in: Account::FUNS

  REASON_CODES = {
    Account::UNKNOWN => 0,
    Account::FIX => 1,
    Account::STRIKE_FEE => 100,
    Account::STRIKE_ADD => 110,
    Account::STRIKE_SUB => 120,
    Account::STRIKE_UNLOCK => 130,
    Account::ORDER_SUBMIT => 600,
    Account::ORDER_CANCEL => 610,
    Account::ORDER_FULLFILLED => 620,
    Account::CLOUD_SAFE_BUY => 700,
    Account::CLOUD_SAFE_SELL => 710,
    Account::SEND_COIN => 720,
    Account::RECEIVE_COIN => 730,
    Account::WITHDRAW_LOCK => 800,
    Account::WITHDRAW_UNLOCK => 810,
    Account::DEPOSIT => 1000,
    Account::WITHDRAW => 2000,
    Account::ARB => 3000,
    Account::WITHDRAW_TAO => 2100,
    Account::TAOCOIN_EXCHANGE => 900,
    Account::CREDIT_CARD => 111,
    Account::BONUS => 888,
    Account::BONUS_AFFILIATE => 999, #bonus 500 KBR in affiliate programs and 0.1BTC
    Account::INVITE_BONUS => 8888,
    Account::SEND_PROFIT => 3001,
    Account::COIN_TRADE_BID => 4000,
    Account::COIN_TRADE_ASK => 4100,
    Account::HARD_FORK_BCH => 5000,
    Account::KBR_FEE => 6000,
    Account::WITHDRAW_KBR => 6100, }
  enumerize :reason, in: REASON_CODES, scope: true

  belongs_to :account
  belongs_to :member
  belongs_to :modifiable, polymorphic: true

  scope :history, -> { with_reason(*HISTORY).reverse_order }

  # Use account balance and locked columes as optimistic lock column. If the
  # passed in balance and locked doesn't match associated account's data in
  # database, exception raise. Otherwise the AccountVersion record will be
  # created.
  #
  # TODO: find a more generic way to construct the sql
  def self.optimistically_lock_account_and_create!(balance, locked, attrs)
    attrs = attrs.symbolize_keys

    attrs[:created_at] = Time.now
    attrs[:updated_at] = attrs[:created_at]
    attrs[:fun]        = Account::FUNS[attrs[:fun]]
    attrs[:reason]     = REASON_CODES[attrs[:reason]]
    attrs[:currency]   = Currency.enumerize[attrs[:currency]]

    account_id = attrs[:account_id]
    raise ActiveRecord::ActiveRecordError, "account must be specified" unless account_id.present?

    qmarks       = (['?']*attrs.size).join(',')
    values_array = [qmarks, *attrs.values]
    values       = ActiveRecord::Base.send :sanitize_sql_array, values_array

    select = Account.unscoped.select(values).where(id: account_id, balance: balance, locked: locked).to_sql
    stmt   = "INSERT INTO account_versions (#{attrs.keys.join(',')}) #{select}"

    connection.insert(stmt).tap do |id|
      if id == 0
        record = new attrs
        raise ActiveRecord::StaleObjectError.new(record, "create")
      end
    end
  end

  def detail_template
    if self.detail.nil? || self.detail.empty?
      return ["system", {}]
    end

    [self.detail.delete(:tmp) || "default", self.detail || {}]
  end

  def amount_change
    balance + locked
  end

  def in
    amount_change > 0 ? amount_change : nil
  end

  def out
    amount_change < 0 ? amount_change : nil
  end

  alias :template :detail_template
end
