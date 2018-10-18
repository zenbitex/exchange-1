class CreateCoinTradePrices < ActiveRecord::Migration
  def change
    create_table :coin_trade_prices do |t|
      t.integer :currency
      t.integer :payment_type
      t.decimal :price, precision: 32, scale: 16 # not origin price
      t.float :fee
      t.string :trade_type
      t.boolean :activate_price

      t.timestamps
    end
  end
end
