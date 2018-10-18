class AddAccountClassToMembers < ActiveRecord::Migration
  def change
    add_column :members, :account_class, :integer
  end
end
