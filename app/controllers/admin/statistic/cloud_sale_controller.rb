module Admin
	module Statistic
		class CloudSaleController < BaseController
		  def index
		  	@start_period = params[:start_period]
		  	@end_period = params[:end_period]
		  	@tao_trades = TaocoinTrades.search(start_period: @start_period,end_period: @end_period).where(:status_id => 1).page params[:page]
		  	@total_amount = @tao_trades.sum(:amount)
		  end

		  def show
		  end
		end
	end
end
