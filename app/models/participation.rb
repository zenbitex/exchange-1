class Participation < ActiveRecord::Base
  belongs_to :member
  belongs_to :chat

  validates :member_id, presence: true, uniqueness: {:scope => :chat_id}
  validates :chat_id, presence: true
end
