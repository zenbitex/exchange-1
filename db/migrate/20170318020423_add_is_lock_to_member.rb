class AddIsLockToMember < ActiveRecord::Migration
  def change
    add_column :members, :is_lock, :integer
  end
end
