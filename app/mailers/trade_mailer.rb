class TradeMailer < BaseMailer
  # default from: "no-reply@bit-itrade.com"

  def trade_email(trade_id)
    @trade = TaocoinTrades.find_by_id(trade_id)
    mail :to => @trade.account.member.email
  end

  def btc_trade_email(trade_id)
    @trade = TaocoinTrades.find_by_id(trade_id)
    mail :to => @trade.account.member.email
  end

  def paypal_email(trade_id)
  	@trade = TaocoinTrades.find_by_id(trade_id)
    mail :to => @trade.account.member.email
  end
end