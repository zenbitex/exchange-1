class AddJobTypeTradePurposeToIdDocument < ActiveRecord::Migration
  def change
    add_column :id_documents, :job_type, :string
    add_column :id_documents, :trade_purpose, :string
  end
end
