class CreateColdWallets < ActiveRecord::Migration
  def change
    create_table :cold_wallets do |t|
      t.string :currency
      t.string :address
      t.decimal :amount, :precision => 32, :scale => 16
      t.string :txid

      t.timestamps
    end
  end
end
