class AddCompanyToIdDocuments < ActiveRecord::Migration
  def change
    add_column :id_documents, :company_name, :string
    add_column :id_documents, :company_country, :string
    add_column :id_documents, :company_zipcode, :string
    add_column :id_documents, :company_city,    :string
    add_column :id_documents, :company_address, :text
    add_column :id_documents, :company_job_content, :string
    add_column :id_documents, :company_trade_purpose, :string
    add_column :id_documents, :manager_name, :string
    add_column :id_documents, :manager_birth_date, :date
    add_column :id_documents, :manager_position, :string
    add_column :id_documents, :manager_country, :string
    add_column :id_documents, :manager_city,    :string
    add_column :id_documents, :manager_address, :text
    add_column :id_documents, :manager_zipcode, :string
    add_column :id_documents, :manager_foreign, :integer
    add_column :id_documents, :manager_role, :integer
    add_column :id_documents, :type_role, :integer
    add_column :id_documents, :position, :string
    add_column :id_documents, :user_type, :integer
  end
end
