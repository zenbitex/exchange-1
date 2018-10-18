class AddIsAddressToIdDocument < ActiveRecord::Migration
  def change
    add_column :id_documents, :is_address, :integer
  end
end
