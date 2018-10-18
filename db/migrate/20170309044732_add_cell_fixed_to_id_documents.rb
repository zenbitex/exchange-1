class AddCellFixedToIdDocuments < ActiveRecord::Migration
  def change
    add_column :id_documents, :cell_phone, :integer
    add_column :id_documents, :fixed_phone, :integer
  end
end
