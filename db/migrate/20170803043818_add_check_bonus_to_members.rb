class AddCheckBonusToMembers < ActiveRecord::Migration
  def change
    add_column :members, :check_bonus_verify, :boolean
    add_column :members, :check_bonus_trade, :boolean
  end
end
