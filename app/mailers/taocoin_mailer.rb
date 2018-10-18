class TaocoinMailer < BaseMailer

  def banks_taocoin_trades(trade_id)
  	@trade = TaocoinTrades.find_by_id(trade_id)
    mail :to => @trade.account.member.email
  end

  def reject_trades(trade_id)
  	@trade = TaocoinTrades.find_by_id(trade_id)
    mail :to => @trade.account.member.email
  end

  def bonus(email)
    mail :to => email
  end

  def bonus_missing(email)
    mail :to => email
  end
end
