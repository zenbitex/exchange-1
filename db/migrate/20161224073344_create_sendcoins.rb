class CreateSendcoins < ActiveRecord::Migration
  def change
    create_table :sendcoins do |t|
      t.integer :user_id_source
      t.integer :user_id_destination
      t.decimal :amount, precision: 32, scale: 16
      t.string :email
      t.string :currency

      t.timestamps
    end
  end
end
