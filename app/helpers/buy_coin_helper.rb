module BuyCoinHelper
  def type_to_text(type)
    case type
    when "CoinTradeBid"
      t('.buy')
    when "CoinTradeAsk"
      t('.sell')
    end
  end
end
