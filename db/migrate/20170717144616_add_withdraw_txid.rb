class AddWithdrawTxid < ActiveRecord::Migration
  def change
    add_column :coin_trades, :withdraw_txid, :string   #withdraw from kraken
    add_column :coin_trades, :type, :string   #Single table inheritance
  end
end
