class AddBonusAffiliateToMember < ActiveRecord::Migration
  def change
    add_column :members, :check_bonus_deposit, :boolean
  end
end
