class Identity < OmniAuth::Identity::Models::ActiveRecord
  has_secure_password
  auth_key :email
  attr_accessor :old_password, :referrer_member_id

  MAX_LOGIN_ATTEMPTS = 5

  validates :email, presence: true, uniqueness: true, email: true
  validates :password, presence: true, length: { minimum: 6, maximum: 64 }
  validates :password_confirmation, presence: true, length: { minimum: 6, maximum: 64 }

  before_validation :sanitize

  def increment_retry_count
    self.retry_count = (retry_count || 0) + 1
  end

  def too_many_failed_login_attempts
    retry_count.present? && retry_count >= MAX_LOGIN_ATTEMPTS
  end

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  def self.valid_email?(email)
    email.present? &&(email =~ VALID_EMAIL_REGEX)
  end

  private

  def sanitize
    self.email.normalize_zen_han.try(:downcase!)
  end

end
