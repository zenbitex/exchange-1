class CreateEmailSendCoins < ActiveRecord::Migration
  def change
    create_table :email_send_coins do |t|
      t.integer :member_id
      t.string :label
      t.string :email

      t.timestamps
    end
  end
end
