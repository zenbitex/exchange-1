class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    if params[:contact][:from_email].include? "sample"
      @contact = Contact.new
      render :new
      return
    end

    new_contact = Contact.new(
      :category => params[:contact][:category],
      :from_email => params[:contact][:from_email],
      :name => params[:contact][:name],
      :message => params[:contact][:message]
    )

    begin
      notifier = Slack::Notifier.new(Rails.application.config.slack_webhook_url)
      message = {
        "text": "<!channel> Check it out. \n *From* : `#{params[:contact][:from_email]}` \n *内容*: \n #{params[:contact][:message]}",
        "mrkdwn": true
      }
      notifier.ping(message)

    rescue StandardError => bang
      puts "Slack notify error"
    end

    user = Contact.where(from_email: params[:contact][:from_email])[-3]
    if !user.nil?
      time = Time.now - user.created_at
      if time <= 24*60*60
        flash.now[:alert] = t('.notice.sorry')
      else
        if new_contact.save
          ContactMailer.send_contact(params[:contact]).deliver
          flash.now[:notice] = t('.notice.ok')
        else
          flash.now[:alert] = t('.notice.fails')
        end
      end
    else
      if new_contact.save
        ContactMailer.send_contact(params[:contact]).deliver
        flash.now[:notice] = t('.notice.ok')
      else
        flash.now[:alert] = t('.notice.fails')
      end
    end
    @contact = Contact.new
    render :new
  end
end
