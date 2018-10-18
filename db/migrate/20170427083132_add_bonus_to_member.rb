class AddBonusToMember < ActiveRecord::Migration
  def change
    add_column :members, :bonus, :integer
  end
end
