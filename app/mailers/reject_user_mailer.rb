class RejectUserMailer < BaseMailer
  def inadequate_document_mail(id)
    @user = Member.find_by_id(id)
    mail :to => @user[:email]
  end

  def incomplete_input_mail(id)
    @user = Member.find_by_id(id)
    mail :to => @user[:email]
  end

  def image_unknown_mail(id)
    @user = Member.find_by_id(id)
    mail :to => @user[:email]
  end
end
