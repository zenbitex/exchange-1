class CreateFcmTokens < ActiveRecord::Migration
  def change
    create_table :fcm_tokens do |t|
      t.string :token
      t.integer :member_id
      t.boolean :enable, :default => true

      t.timestamps
    end
  end
end
