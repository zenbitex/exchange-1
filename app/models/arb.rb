class Arb < ActiveRecord::Base
	belongs_to :member
	# validates_numericality_of :tao_amount, :greater_than => 1
	# validates_presence_of :tao_amount

  def self.current_amount_of(user_id)
    # current one user - one records in arbs table
    current_user_arb = Arb.find_by(:member_id => user_id)
    current_user_arb_amount = 0
    if !current_user_arb.nil?
      current_user_arb_amount = current_user_arb.tao_amount.to_f
    end
    current_user_arb_amount
  end

end
