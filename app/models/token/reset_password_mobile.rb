class Token::ResetPasswordMobile < ::Token
  after_create :send_token

  def confirm!
    super
    member.active!
  end

  private

  def send_token
    TokenMailer.reset_password_mobile(member.email, token).deliver
  end
end
