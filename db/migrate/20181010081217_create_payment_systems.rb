class CreatePaymentSystems < ActiveRecord::Migration
  def change
    create_table :payment_systems do |t|
      t.string :payment_id
      t.integer :member_id
      t.string :address
      t.float :payment_amount
      t.float :amount_received, default: 0
      t.integer :currency
      t.string :txid
      t.string :payment_infor
      t.string :status, default: "unsent"

      t.timestamps
    end
  end
end
