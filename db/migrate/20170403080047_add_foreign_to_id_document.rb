class AddForeignToIdDocument < ActiveRecord::Migration
  def change
    add_column :id_documents, :foreign, :integer
  end
end
