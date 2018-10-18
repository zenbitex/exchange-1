class Token::ActivationEmailMobile < ::Token
  after_create :send_token

  def confirm!
    super
    member.active!
  end

  private

  def send_token
    TokenMailer.activation_mobile(member.email, token).deliver
  end
end
