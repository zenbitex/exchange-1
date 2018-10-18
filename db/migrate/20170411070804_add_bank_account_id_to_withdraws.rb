class AddBankAccountIdToWithdraws < ActiveRecord::Migration
  def change
    add_column :withdraws, :bank_account_id, :integer
  end
end
