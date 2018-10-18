module Admin
	class PaypaltradesController < BaseController
	  def index
	  	@trades = TaocoinTrades.where(:currency => "usd").page(params[:page]).per(200).order("id DESC")
	  end

	  def show
	  	@trade = TaocoinTrades.find_by_id(params[:id])
	  end
	end
end
