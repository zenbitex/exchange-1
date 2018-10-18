class CreateArbs < ActiveRecord::Migration
  def change
    create_table :arbs do |t|
      t.integer :member_id
      t.decimal :tao_amount, precision: 32, scale: 16
      t.float :profit

      t.timestamps
    end
  end
end
