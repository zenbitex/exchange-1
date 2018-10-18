class AddCheckBonusAccActiveToMember < ActiveRecord::Migration
  def change
    add_column :members, :check_bonus_acc_active, :boolean
  end
end
