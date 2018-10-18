class AddBidFeeToTrade < ActiveRecord::Migration
  def change
    add_column :trades, :bid_fee, :decimal, precision: 32, scale: 16
  end
end
