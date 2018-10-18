class AddMasterSeedToPaymentAddress < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :master_seed, :string
  end
end
