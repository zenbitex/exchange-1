module V1
	class Mount < Grape::API
  	PREFIX = '/api'
  	version 'v1', using: :path
  	format :json
  	default_format :json

    before do
      header 'Access-Control-Allow-Origin', '*'
    end

    mount Accounts
	end
end