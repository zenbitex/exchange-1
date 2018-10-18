class CreateArbProfits < ActiveRecord::Migration
  def change
    create_table :arb_profits do |t|
      t.integer :member_id
      t.decimal :tao_profit, precision: 32, scale: 16
      t.decimal :weight_profit, precision: 32, scale: 16

      t.timestamps
    end
  end
end
