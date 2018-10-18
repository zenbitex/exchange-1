module APIv2
  module Entities
    class TaocoinTradeBTC < Base
      expose :tradecode
      expose (:email) { |trade| trade.account.member.email}
      expose :amount
      expose :price
      expose :exchangerate, :unless => Proc.new {|g| g.exchangerate.nil?}
      expose :status_id
      expose :currency
      expose (:fund_source) {|trade| TaocoinFundSources.find_by_id(trade.taocoin_fund_source_id).btc_address}
      expose :created_at, format_with: :iso8601
    end
  end
end
