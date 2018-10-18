class AddTxidToTaocoinTrades < ActiveRecord::Migration
  def change
    add_column :taocoin_trades, :txid, :string
  end
end
