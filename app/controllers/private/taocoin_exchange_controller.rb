module Private
	class TaocoinExchangeController < BaseController
		#layout false
	  before_action :auth_activated!
	  before_action :auth_verified!
	  before_action :two_factor_activated!
	  before_action :lock

	  def new
	  	@taocoin_exchange = current_user.taocoin_exchanges.build
	  	@rate = ExchangeRates.where.not(:id => 3)
	  	@currencies_summary = Currency.all.map(&:summary)
	    @currencies_summary.each do |c|
	        if !c[:coinable]
	          @currencies_summary.delete(c)
	        end
	    end
	  end

	  def create
	  	data = params[:data_text]

	  	save_db = TaocoinExchange.new(:currency => data['currency'], :amount => data["amount"], :member_id => current_user.id, :total => data['total'])

	  	rate_confirm = ExchangeRates.find_by(:id => data['currency']).rate
	  	if data['currency'].to_i == 1
	  		total_confirm = (data["amount"].to_i * rate_confirm.to_f).floor
	  	elsif data['currency'].to_i == 2
	  		total_confirm = (data["amount"].to_i * rate_confirm.to_f * 100000.to_f).floor/100000.to_f
	  	end

	  	if data["total"].to_f == total_confirm

	  		buyer_account = current_user.accounts.find_by_currency(data['currency'])
	  		seller_account = Account.find_by(:member_id => 1,:currency => data['currency'])
	  		buyer_account_tao = current_user.accounts.find_by_currency(3)
	  		seller_account_tao = Account.find_by(:member_id => 1,:currency => 3)

	  		if buyer_account_tao.balance < data["amount"].to_f
	  			data_error = {"amount_account_not_enough" => true}
	  			render :json => data_error, status: 301
	  		elsif seller_account.balance < data["total"].to_f
	  			data_error = {"amount_admin_not_enough" => true}
	  			render :json => data_error, status: 302
		  	elsif buyer_account_tao.balance >= data["amount"].to_f && seller_account.balance >= data["total"].to_f
		  	 	if save_db.save
			  		buyer_account.lock!.plus_funds data['total'].to_f, reason: Account::TAOCOIN_EXCHANGE, ref: nil
			  		seller_account.lock!.sub_funds data['total'].to_f, reason: Account::TAOCOIN_EXCHANGE, ref: nil

			  		buyer_account_tao.lock!.sub_funds data["amount"].to_i, reason: Account::TAOCOIN_EXCHANGE, ref: nil
			  		seller_account_tao.lock!.plus_funds data["amount"].to_i, reason: Account::TAOCOIN_EXCHANGE, ref: nil

			  		# redirect_to funds_path, text: I18n.t('.exchange_success')
			  		data_success = {"success" => true}
					  render :json => data_success, status: 200 
					  
			  	else
			  		data_error = {"save_error" => true}
			  		render :json => data_error, status: 300
			  	end
		  	end
	  	else
	  		data_error = {"total_error" => true}
	  		render :json => data_error, status: 300
	  	end

	  end

	  def lock
	  	redirect_to "/404.html"
	  end
	end
end