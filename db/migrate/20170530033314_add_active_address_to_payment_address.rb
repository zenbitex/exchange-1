class AddActiveAddressToPaymentAddress < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :active_ripple, :boolean
  end
end
