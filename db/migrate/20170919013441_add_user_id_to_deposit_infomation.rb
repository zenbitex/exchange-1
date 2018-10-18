class AddUserIdToDepositInfomation < ActiveRecord::Migration
  def change
    add_column :deposit_infomations, :user_id, :integer
  end
end
