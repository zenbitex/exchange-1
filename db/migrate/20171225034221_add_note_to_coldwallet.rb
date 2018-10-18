class AddNoteToColdwallet < ActiveRecord::Migration
  def change
    add_column :cold_wallets, :note, :text
  end
end
