class CreateFeeTrades < ActiveRecord::Migration
  def change
    create_table :fee_trades do |t|
      t.integer :currency
      t.decimal :amount, precision: 32, scale: 16

      t.timestamps
    end
  end
end
