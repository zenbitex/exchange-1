class Contact < ActiveRecord::Base
  validates :name, presence: true
  validates :message, presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :from_email, presence: true, format: { with: VALID_EMAIL_REGEX }
end
