class AddIsAdminToMember < ActiveRecord::Migration
  def change
    add_column :members, :is_admin, :boolean
    add_column :members, :is_root, :boolean
  end
end
