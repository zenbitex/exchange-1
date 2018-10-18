class AddDestinationTagToWithdraw < ActiveRecord::Migration
  def change
    add_column :withdraws, :destination_tag, :string
  end
end
