class CreateBuyCoins < ActiveRecord::Migration
  def change
    create_table :buy_coins do |t|
      t.string :id_buy
      t.string :market
      t.float :money
      t.float :price
      t.float :amount
      t.integer :status

      t.timestamps
    end
  end
end
