class CreateDepositInfomations < ActiveRecord::Migration
  def change
    create_table :deposit_infomations do |t|
      t.integer :member_id
      t.string :payer_name
      t.decimal :amount, precision: 32, scale: 16
      t.text :memo
      t.date :date_deposit
      t.string :aasm_state

      t.timestamps
    end
  end
end
