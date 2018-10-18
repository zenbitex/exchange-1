class AddPurchasedAtToTaocoinTrades < ActiveRecord::Migration
  def change
    add_column :taocoin_trades, :purchased_at, :string
  end
end
