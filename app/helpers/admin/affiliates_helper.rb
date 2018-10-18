module Admin::AffiliatesHelper
  def bonus_need_pay bonus, bonus_paid
    bonus_paid = 0 if bonus_paid.nil?
    if bonus.present?
      return bonus - bonus_paid
    end
  end

  def get_name id
    Member.where(id: id).first.id_document.name
  end

  def count_people_intro id
    Member.where(affiliate_member_id: id).count
  end

  def object_member id
    Member.find_by_id(id)
  end
  def sum_btc_trade(user)
    btc_exchange_ask = Market.all.select {|x| x.base_unit == 'btc'}
    btc_exchange_code_ask = btc_exchange_ask.map(&:code)
    btc_ask = user.trades.select {|x| x["currency"].in? btc_exchange_code_ask}
    btc_ask_sum = btc_ask.sum(&:volume).to_f

    btc_exchange_bid = Market.all.select {|x| x.quote_unit == 'btc'}
    btc_exchange_code_bid = btc_exchange_bid.map(&:code)
    btc_bid = user.trades.select {|x| x["currency"].in? btc_exchange_code_bid}
    btc_bid_sum = btc_bid.sum(&:price).to_f

    return btc_ask_sum + btc_bid_sum
  end
end
