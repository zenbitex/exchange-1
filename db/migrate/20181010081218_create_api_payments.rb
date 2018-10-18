class CreateAPIPayments < ActiveRecord::Migration
  def change
    create_table :api_payments do |t|
      t.integer :member_id
      t.string :access_key
      t.string :secret_key
      t.integer :requires_in_1_minute
      t.boolean :is_lock
      t.date :time_required
      
      t.timestamps
    end
  end
end
