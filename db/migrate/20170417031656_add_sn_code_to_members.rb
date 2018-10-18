class AddSnCodeToMembers < ActiveRecord::Migration
  def change
    add_column :members, :sn_code, :string
  end
end
