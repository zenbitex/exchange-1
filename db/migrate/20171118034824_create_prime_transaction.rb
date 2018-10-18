class CreatePrimeTransaction < ActiveRecord::Migration
  def change
    create_table :prime_transactions do |t|
      t.string :txid
      t.string :address_destination
      t.string :address_from
      t.decimal :amount, :precision => 32, :scale => 16
      t.date :receive_at
      t.integer :currency

      t.timestamps
    end
  end
end
