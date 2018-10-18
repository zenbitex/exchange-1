class ArbProfit < ActiveRecord::Base
  belongs_to :member

  def self.search(condition)
    member_id_list = IdDocument.where("name LIKE ?", "%#{condition}%").pluck(:member_id)
    member_id_list << condition.to_i
    ArbProfit.where("member_id IN (?) ", member_id_list)
  end
end
