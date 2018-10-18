module APIv2
	module Entities
		class History < Base
			expose :id
			expose :tradecode
			expose :amount
			expose :price
			expose :currency
			expose :status_id
			expose :created_at
		end
	end
end