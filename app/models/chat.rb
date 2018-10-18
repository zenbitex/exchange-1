class Chat < ActiveRecord::Base
  # Owner
  belongs_to :owner_member, class_name: 'Member', foreign_key: :owner_id

  # Many to Many with User
  has_many :participations, dependent: :destroy
  has_many :members, through: :participations, source: :member

  has_many :messages, dependent: :destroy
end
