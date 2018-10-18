class CreateTaocoinExchanges < ActiveRecord::Migration
  def change
    create_table :taocoin_exchanges do |t|
      t.integer :member_id
      t.integer :amount
      t.decimal :total, precision: 32, scale: 16
      t.integer :currency

      t.timestamps
    end
  end
end
