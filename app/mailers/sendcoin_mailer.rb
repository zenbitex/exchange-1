class SendcoinMailer < BaseMailer

	def sendcoin(id)
		@sendcoin = Sendcoin.find(id)
		case @sendcoin.currency
		when '2'
			@currency = 'BTC'
		when '3'
			@currency = 'TAOCOIN'
		end
		email = Member.find(@sendcoin.user_id_source).email
		mail :to => email
	end

	def receivecoin(id)
		@sendcoin = Sendcoin.find(id)
		case @sendcoin.currency
		when '2'
			@currency = 'BTC'
		when '3'
			@currency = 'TAOCOIN'
		end
		@source = Member.find(@sendcoin.user_id_source).email
		mail :to => @sendcoin.email
	end

end