require 'tubesock'
class ChatsController < ApplicationController
  before_filter :auth_member!
  layout 'chat'
  include Tubesock::Hijack
  before_action :set_chat, only: [:show, :edit, :update, :destroy, :chat, :messages]

  def index
    render json: Chat.all
  end

  def show
    render json: @chat
  end

  def create
    @chat = current_user.owned_chats.build(chat_params)

    respond_to do |format|
      if @chat.save
        current_user.join_in @chat
        format.html {redirect_to @chat}
        format.json {render json: @chat, status: :created, location: @chat}
      else
        format.html {render action: "new" }
        format.json {render json: @chat.errors, status: :unprocessable_entity}
      end
    end
  end

  def messages
    @messages = []
    @chat.messages.each do |m|
      user = Participation.find_by(member_id: m.sent_id)
      @messages << {message: m, owner: user}
    end
    render json: @messages
  end

  def chatting
    if current_user.admin? && current_user.role == 1
      if Chat.all.count == 0
        Chat.create(name: "Chatting", owner_id: 1)
      end
    end
  end

  def get_name
    chat_user = Participation.where(member_id: current_user.id)
    if chat_user && chat_user[0] && chat_user[0]['chat_name']
      render json: {name: chat_user[0]['chat_name']}
    else
      render json: {name: current_user.email}
    end
  end

  def change_name
    chat_user = Participation.where(member_id: current_user.id)
    if chat_user && chat_user[0]
      success = chat_user[0].update(chat_name: params[:chatname])
    else
      success = Participation.create(member_id: current_user.id, chat_id: 1, chat_name: params[:chatname])
    end
    render json: {success: success}
  end
  
  def chat
    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new.subscribe "Chat_#{@chat.id}" do |on|
          on.message do |channel, message|
            tubesock.send_data message

          end
        end
      end

      tubesock.onmessage do |m|
        # pub the message when we get one
        # note: this echoes through the sub above
        m = JSON.parse(m)
        @chat.messages.create(content: m['message'], sent_id: current_user.id)
        date = @chat.messages.last.created_at
        user = Participation.find_by(member_id: current_user.id)
        if user
          username = !user.chat_name.nil? ? user.chat_name : current_user.email
        else
          username = current_user.email
        end
        m = {"username" => username, "message" => m['message'], "date" => date}.to_json 
        Redis.new.publish "Chat_#{@chat.id}", m
      end

      tubesock.onclose do
        # stop listening when client leaves
        redis_thread.kill
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def chat_params
      params.require(:chat).permit(:name)
    end

end
