module APIv2
  class FcmTokens < Grape::API
    desc "Push fcm token", hidden: true
    params do
      requires :token, type: String
      requires :fcm_token, type: String
    end
    post "/push_fcm_token" do
      return json_error "bad_request" if params[:token].nil?
      result = JsonWebToken.verify(params[:token], key: ENV['JWT_SECRET'])
      if result[:ok]
        email = result[:ok][:email]
        member = Member.find_by_email(email)
        if member.fcm_tokens.find_by(:token => params[:fcm_token])
          fcm_token = member.fcm_tokens.find_by(:token => params[:fcm_token])
          if !fcm_token.enable?
            fcm_token.enable!
          end
        else
          member.fcm_tokens.create(:token => params[:fcm_token])
        end
        {
          "success" => true,
          "results" => [
            {
              "success" => true
            }
          ]
        }
      else
        json_error "invalid_token"
      end
    end
    #---------------------------------------------#
    desc "Disable fcm token", hidden: true
    params do
      requires :token, type: String
      requires :fcm_token, type: String
    end
    post "/disable_fcm_token" do
      return json_error "bad_request" if params[:token].nil?
      result = JsonWebToken.verify(params[:token], key: ENV['JWT_SECRET'])
      if result[:ok]
        email = result[:ok][:email]
        member = Member.find_by_email(email)
        if member.fcm_tokens.find_by(:token => params[:fcm_token])
          fcm_token = member.fcm_tokens.find_by(:token => params[:fcm_token])
          if fcm_token.enable?
            fcm_token.disable!
          end
        end
        {
          "success" => true,
          "results" => [
            {
              "success" => true
            }
          ]
        }
      else
        json_error "invalid_token"
      end
    end
  end
end