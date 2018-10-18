class CreateCreditSetupPrices < ActiveRecord::Migration
  def change
    create_table :credit_setup_prices do |t|
      t.string :market
      t.float :price
      t.integer :enable

      t.timestamps
    end
  end
end
