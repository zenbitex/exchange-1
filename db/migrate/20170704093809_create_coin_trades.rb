class CreateCoinTrades < ActiveRecord::Migration
  def change
    create_table :coin_trades do |t|
      t.integer :member_id
      t.string :currency
      t.string :payment_type
      t.decimal :amount, precision: 32, scale: 16
      t.decimal :price, precision: 32, scale: 16
      t.decimal :total, precision: 32, scale: 16
      t.string :trade_type

      t.timestamps
    end
  end
end
