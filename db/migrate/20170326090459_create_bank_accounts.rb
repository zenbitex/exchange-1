class CreateBankAccounts < ActiveRecord::Migration
  def change
    create_table :bank_accounts do |t|
      t.integer :member_id
      t.string :bank_name
      t.string :bank_branch
      t.integer :account_type
      t.string :account_number
      t.string :owner
      t.timestamps
    end
  end
end