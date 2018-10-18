class ReplyUser < BaseMailer
  # default from: "from@example.com"

  def send_email_user(user)
  	@user = user
  	mail :to => @user["from_email"], :subject => @user["subject"]
  end

end
