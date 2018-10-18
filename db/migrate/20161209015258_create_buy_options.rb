class CreateBuyOptions < ActiveRecord::Migration
  def change
    create_table :buy_options do |t|
      t.decimal :taocoin, :precision => 32, :scale => 16
      t.string :currency
      t.decimal :amount, :precision => 32, :scale => 16

      t.timestamps
    end
  end
end
