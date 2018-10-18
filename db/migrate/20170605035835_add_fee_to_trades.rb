class AddFeeToTrades < ActiveRecord::Migration
  def change
    add_column :trades, :fee, :decimal, precision: 32, scale: 16
  end
end
