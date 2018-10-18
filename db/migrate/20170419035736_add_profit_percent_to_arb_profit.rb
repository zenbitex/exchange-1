class AddProfitPercentToArbProfit < ActiveRecord::Migration
  def change
    add_column :arb_profits, :profit_percent, :decimal, precision: 32, scale: 16
  end
end