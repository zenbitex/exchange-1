module Admin
	class BuyOptionsController < BaseController
	  def index
	  	@buyoptions = BuyOptions.all
	  end

	  def show
	  end

	  def edit
	  	@buyoption = BuyOptions.find(params[:id])
	  end

	  def update
	  	  @buyoption = BuyOptions.find(params[:id])
	      if @buyoption.update_attributes(exc_params)
	        redirect_to admin_buy_options_path
	      else
	        render :edit 
	      end
	  end

	  private
	  def exc_params
	  	params.require(:buy_options).permit(:amount, :taocoin)
	  end
	end
end
