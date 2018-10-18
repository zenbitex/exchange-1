class Message < ActiveRecord::Base
  belongs_to :owner, class_name: :Member, foreign_key: :sent_id
  belongs_to :chat
end
