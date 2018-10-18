module Admin
	class ExchangeratesController < BaseController
	    def index
	  	@excrates = ExchangeRates.all
	  end

	  def show
	  end

	  def edit
	  	@excrate = ExchangeRates.find(params[:id])
	  end

	  def update
	  	  @excrate = ExchangeRates.find(params[:id])
	      if @excrate.update_attributes(exc_params)
	      	#flash[:note] = "Update successfuly"
	        redirect_to admin_exchangerates_path
	      else
	        render :edit 
	      end
	  end

	  private
	  def exc_params
	  	params.require(:exchange_rates).permit(:currency, :rate)
	  end
	end
end