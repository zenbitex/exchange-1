class AddToCoinTrade < ActiveRecord::Migration
  def change
    add_column :coin_trades, :txid, :string   #order in kraken
    add_column :coin_trades, :aasm_state, :string
    add_column :coin_trades, :origin_price, :decimal, precision: 32, scale: 16
  end
end
