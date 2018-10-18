class OrderAsk < Order

  has_many :trades, foreign_key: 'ask_id'

  validate :ensure_account_balance, on: :create

  scope :matching_rule, -> { order('price ASC, created_at ASC') }

  def get_account_changes(trade)
    [trade.volume, trade.funds]
  end

  def hold_account
    member.get_account(ask)
  end

  def expect_account
    member.get_account(bid)
  end

  def avg_price
    return ::Trade::ZERO if funds_used.zero? || config.nil?
    config.fix_number_precision(:bid, funds_received / funds_used)
  end

  def compute_locked
    case ord_type
    when 'limit'
      volume
    when 'market'
      estimate_required_funds(Global[currency].bids) {|p, v| v}
    end
  end

  def ensure_account_balance
    if self.origin_volume > member.accounts.find_by_currency(self.ask_value).balance
      errors.add(:amount, I18n.t("private.markets.show.insufficient_funds", currency: self.ask.upcase))
    end
  end

end
