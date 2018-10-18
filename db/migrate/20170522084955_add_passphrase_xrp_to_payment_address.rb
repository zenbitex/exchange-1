class AddPassphraseXrpToPaymentAddress < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :passphrase_xrp, :string
  end
end
