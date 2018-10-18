class ContactMailer < BaseMailer

  def send_contact(user_contact)
  	@user_contact = user_contact
    mail :to => "kuberasalemail@gmail.com", :subject => "[BIT-TRADING-SUPORT] #{@user_contact["name"]}"
  end

end
