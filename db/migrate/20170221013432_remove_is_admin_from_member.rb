class RemoveIsAdminFromMember < ActiveRecord::Migration
  def change
    remove_column :members, :is_admin, :boolean
    remove_column :members, :is_root, :boolean
  end
end
