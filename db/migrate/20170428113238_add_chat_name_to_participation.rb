class AddChatNameToParticipation < ActiveRecord::Migration
  def change
    add_column :participations, :chat_name, :string
  end
end
