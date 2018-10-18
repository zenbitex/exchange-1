class AddFeetoColdWallet < ActiveRecord::Migration
  def change
  	add_column :cold_wallets, :fee, :decimal, precision: 32, scale: 16
  	add_column :cold_wallets, :sum, :decimal, precision: 32, scale: 16
  end
end
