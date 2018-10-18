class AddIsLoginToIdentity < ActiveRecord::Migration
  def change
    add_column :identities, :is_login, :boolean
  end
end
