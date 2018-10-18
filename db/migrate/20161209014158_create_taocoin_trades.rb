class CreateTaocoinTrades < ActiveRecord::Migration
  def change
    create_table :taocoin_trades do |t|
      t.string :tradecode
      t.string :address
      t.integer :amount
      t.decimal :exchangerate, :precision => 32, :scale => 16
      t.decimal :price, :precision => 32, :scale => 16
      t.integer :status_id
      t.string :currency
      t.string :fund_source
      t.text :notification_params
      t.datetime :purchased
      t.string :token
      t.integer :account_id

      t.timestamps
    end
  end
end
