class TokenMailer < BaseMailer

  def reset_password(email, token)
    @token_url = edit_reset_password_url(token)
    mail to: email
  end

  def activation(email, token)
    @email = email
    @token_url = edit_activation_url token
    mail to: email
  end

  def accepted(email)
  	mail to: email
  end

  def send_code(email, code)
    @code = code
    mail to: email
  end

  def edit_email(email, token_id)
    token = Token.find(token_id)
    @email = email
    @token_url = edit_activation_email_url token
    mail to: email
  end

  def activation_mobile(email, token)
    @email = email
    @token = token
    mail to: email
  end

  def reset_password_mobile(email, token)
    @email = email
    @token = token
    mail to: email
  end
end
