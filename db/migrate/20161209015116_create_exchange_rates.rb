class CreateExchangeRates < ActiveRecord::Migration
  def change
    create_table :exchange_rates do |t|
      t.string :currency
      t.decimal :rate, :precision => 32, :scale => 16

      t.timestamps
    end
  end
end
