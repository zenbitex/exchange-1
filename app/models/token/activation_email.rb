class Token::ActivationEmail < ::Token
  #after_create :send_token

  def confirm!
    super
    member.active!
  end

  private

  def send_token
    TokenMailer.edit_email(member.email, token).deliver
  end
end
