class AccountNumberChangeColumnType < ActiveRecord::Migration
  def change
  	change_column(:bank_accounts, :account_number, :string)
  end

  def up
    change_column :bank_accounts, :account_number, :string
  end

  def down
    change_column :bank_accounts, :account_number, :integer
  end
end
