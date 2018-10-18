class AddNameFeeToFeeTrades < ActiveRecord::Migration
  def change
    add_column :fee_trades, :fee_type, :string
    add_column :buy_coins, :member_id, :integer
    add_column :buy_coins, :fee, :float
  end
end
