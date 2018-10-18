class AddAchievedInviterLv < ActiveRecord::Migration
  def change
    add_column :members, :achieved_inviter_lv, :integer
  end
end
