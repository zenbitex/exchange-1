class AddCheckReplyToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :check_reply, :boolean
  end
end
