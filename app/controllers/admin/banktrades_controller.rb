module Admin
	class BanktradesController < BaseController
	  def index
			if params[:status_id]
				@trades = TaocoinTrades.where(status_id: params[:status_id], :currency => 'jpy').page(params[:page]).per(200).order("id DESC")
				@options = BuyOptions.all
			else
				@trades = TaocoinTrades.where(:currency => 'jpy').page(params[:page]).per(200).order("id DESC")
				@options = BuyOptions.all
			end

			respond_to do |format|
		      format.html { render 'details', :layout => false if request.xhr? }
		      format.js { render 'index' } #index.js.erb
		      format.json { render json: @trades }
		    end

		    if params[:search]
		    	@trades = TaocoinTrades.search(params[:search]).order(sort_column + " " + sort_direction).page(params[:page]).per(200)
		    end
		end

		def show
			@trade = TaocoinTrades.find_by_id(params[:id])

	        selectadmin = Account.find_by(:member_id => 1,:currency => 3)
	        @balance = selectadmin.balance.to_i 
		end

		def update
			#admin_account = Account.select(:balance).where(id: 3)
			@trade = TaocoinTrades.find_by_id(params[:id]) 
			selectadmin = Account.find_by(:member_id => 1,:currency => 3)
			user_account = Account.find_by(:id => @trade.account_id)
			admin_balance = selectadmin.balance.to_i		
			balance_buy = @trade.amount.to_i

			if admin_balance > balance_buy
				# amount_admin = admin_balance - balance_buy

				# amount_user = @trade.account.balance + balance_buy

				# current_user_account = @trade.account.id

				# Account.where(id:3).update_all(balance:amount_admin)
				# Account.where(id:@trade.account_id).update_all(balance:amount_user)
				
				selectadmin = Account.find_by(:member_id => 1,:currency => 3)
		        user_account = Account.find_by(:id => trade.account_id)
		        selectadmin.lock!.sub_funds balance_buy, reason: Account::CLOUD_SAFE_SELL, ref: nil
		        user_account.lock!.plus_funds balance_buy, reason: Account::CLOUD_SAFE_BUY, ref: nil

		        @trade.update_attributes :status_id => 1
		        TaocoinMailer.banks_taocoin_trades(@trade.id).deliver
		    else
		    	flash[:note] = "Your TAOCOIN is not enough"
		    end
	        
	        redirect_to :back
		end

		def destroy
			@trade = TaocoinTrades.find_by_id(params[:id])
	        @trade.update_attributes(status_id: 2)
	        TaocoinMailer.reject_trades(@trade.id).deliver
	        redirect_to :back
		end
	end
end
