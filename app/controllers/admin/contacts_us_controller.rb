module Admin
  class ContactsUsController < BaseController
    def index
      @contacts_us = Contact.all.order("created_at desc").page(params[:page]).per(200)
    end

    def show
      @contact_us = Contact.find_by_id(params[:format])
    end

    def create_send_email
      @contact_reply = Contact.find_by_id(params[:format])
    end

    def rep_ok_ng
      if !params[:id].nil?
        contact = Contact.find_by_id(params[:id])
        if contact.check_reply
          contact.check_reply = false
        else
          contact.check_reply = true
        end
        contact.save
        redirect_to admin_contacts_us_path, :notice => 'Successfull change status'

      else
        redirect_to admin_contacts_us_path, :alert => 'Request Fails'
      end
    end

    def send_mail
      user_send = Contact.find_by_id(params[:id])
      if params[:content] != ""
        email_user = {
          "from_email" => params[:to_email],
          "subject" => params[:subject],
          "content" => params[:content].html_safe
        }
        ReplyUser.send_email_user(email_user).deliver
        user_send.check_reply = true
        user_send.save

        redirect_to admin_contacts_us_path, :notice => 'Send email successfull'
      else
        redirect_to admin_contacts_us_path, :alert => "Please type content"
      end
    end

    def to_all_new
    end

    def send_to_all
      if params[:subject].empty? || params[:content].empty?
        redirect_to admin_contacts_us_to_all_new_path, :alert => "件名と内容をご入力してください。"
      else
        if params[:level].to_i > 0
          activated_members = Member.where("activated=? && account_class=?", 1, params[:level].to_i)
        else
          activated_members = Member.where("activated=?", 1)
        end

        activated_members.each{ |member|
          email_user = {
            "from_email" => member.email,
            "subject" => params[:subject],
            "content" => params[:content].html_safe
          }

          ReplyUser.send_email_user(email_user).deliver
        }
        redirect_to admin_contacts_us_to_all_new_path, :notice => 'Send email successfull'
      end

    end

	end
end
