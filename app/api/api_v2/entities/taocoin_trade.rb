module APIv2
  module Entities
    class TaocoinTrade < Base
      expose :tradecode
      expose (:email) { |trade| trade.account.member.email}
      expose :amount
      expose :price
      expose :exchangerate, :unless => Proc.new {|g| g.exchangerate.nil?}
      expose :status_id
      expose :currency
      expose :created_at, format_with: :iso8601

    end
  end
end
