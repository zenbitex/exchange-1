class CreateArbHistories < ActiveRecord::Migration
  def change
    create_table :arb_histories do |t|
      t.integer :member_id
      t.string :type_arb, precision: 32, scale: 16
      t.decimal :tao_amount

      t.timestamps
    end
  end
end
