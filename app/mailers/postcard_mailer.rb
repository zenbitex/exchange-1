class PostcardMailer < BaseMailer
  def postcard_mailer(user, postcard_type)
    @user = user
    @postcard_type = postcard_type
    
    if postcard_type == 1 
      @subject = "【ビットステーション】 本人認証完了のお知らせ"
    else 
      @subject = "【ビットステーション】書留郵便の発送に関しまして"
    end
    mail :to => @user[:email], :subject => @subject
  end
end
