class AddFeeToCoinTrade < ActiveRecord::Migration
  def change
    add_column :coin_trades, :fee, :decimal, precision: 32, scale: 16
  end
end
