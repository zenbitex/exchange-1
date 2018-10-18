class AddAffiliateMemberIdToMembers < ActiveRecord::Migration
  def change
  	add_column :members, :affiliate_member_id, :integer
  end
end
