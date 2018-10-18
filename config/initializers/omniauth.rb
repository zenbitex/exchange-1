Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, fields: [:email], on_failed_registration: IdentitiesController.action(:new)
  provider :facebook, ENV['FB_KEY'], ENV['FB_SECRET']
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

OmniAuth.config.on_failure = lambda do |env|
  SessionsController.action(:failure).call(env)
end

OmniAuth.config.logger = Rails.logger

module OmniAuth
  module Strategies
   class Identity
     def request_phase
       redirect "/signin#{get_params}"
     end

     def registration_form
       redirect "/signup#{get_params}"
     end

     def get_params
        params_url = request.params
        return "" if params_url.empty?
        content = "?"
        params_url.each do |key, value|
          content += key + "=" + value + "&"
        end
        content[0...(content.length - 1)]
     end
   end
 end
end
