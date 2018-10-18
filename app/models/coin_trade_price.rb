class CoinTradePrice < ActiveRecord::Base
  extend Enumerize

  enumerize :currency, in: Currency.enumerize
  enumerize :payment_type, in: Currency.enumerize

  validates_presence_of :fee, :price, :on => :update
  validates_numericality_of :fee, greater_than: 0, :on => :update
  validates_numericality_of :price, greater_than_or_equal_to: 0, :on => :update
  def self.find_by_market market,trade_type
    code = Market.find(market)
    where('CONCAT(currency, payment_type) = ? AND trade_type = ?', code.ask_currency.id.to_s + code.bid_currency.id.to_s, trade_type).first
  end

end
