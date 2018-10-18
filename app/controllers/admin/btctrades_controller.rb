module Admin
	class BtctradesController < BaseController
	  def index
	  	@trades = TaocoinTrades.where(:currency => "btc").page(params[:page]).per(200).order("id DESC")
	  end

	  def show
	  	@trade = TaocoinTrades.find_by_id(params[:id])
	  end

	  def update
			#admin_account = Account.select(:balance).where(id: 3)
			trade = TaocoinTrades.find_by_id(params[:id]) 
			selectadmin = Account.find_by(:member_id => 1,:currency => 3)
			user_account = Account.find_by(:id => trade.account_id)
			admin_balance = selectadmin.balance.to_i		
			balance_buy = trade.amount.to_i

			if admin_balance > balance_buy				
				selectadmin = Account.find_by(:member_id => 1,:currency => 3)
		        user_account = Account.find_by(:id => trade.account_id)
		        selectadmin.lock!.sub_funds balance_buy, reason: Account::CLOUD_SAFE_SELL, ref: nil
		        user_account.lock!.plus_funds balance_buy, reason: Account::CLOUD_SAFE_BUY, ref: nil
		        trade.update_attributes :status_id => 1
		    else
		    	flash[:note] = "Your TAOCOIN is not enough"
		    end
	        
	        redirect_to :back
		end
	end
end
