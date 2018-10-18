class AddReferrer < ActiveRecord::Migration
  def change
  	add_column :members, :referrer_member_id, :integer
  end
end
