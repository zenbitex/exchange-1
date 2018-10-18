module Admin
	class FlagsController < BaseController
	  def index
	  	@flags = Flags.all
	  end

	  def new
	  	@currencies_summary = Currency.all.map(&:summary)
	    @currencies_summary.each do |c|
	        if !c[:coinable]
	          @currencies_summary.delete(c)
	        end
	    end
	    @flag = Flags.new
	  end

	  def create
	  	@flag = Flags.new(flags_params)
		@f = Flags.where(:flag_name => @flag.flag_name)
		if @f == []
			if @flag.save
				redirect_to admin_flags_path
			else
				flash[:error] = "Opp, have an error, please try again!"
				redirect_to :back
			end
		else
			flash[:error] = "Flag name is exits, cann't add"
			redirect_to :back
		end
	  end

	  def on_flag
	  	@data = params[:data_text]
	  	flag_name = @data['flag_name'].strip
	  	flag_value = @data['flag_value'].strip
	  	
	  	
	  	data = Flags.where(flag_name: flag_name).update_all(value:1)
	  	#binding.pry

	  	render :json => data , status: 200

	  	
	  end

	  def off_flag
	  	@data = params[:data_text]
	  	flag_name = @data['flag_name'].strip
	  	flag_value = @data['flag_value'].strip
	  	
	  	data = Flags.where(flag_name: flag_name).update_all(value:0)
	  	render :json => data , status: 200
	  end

	  private
	  def flags_params
	  	params.require(:flags).permit(:flag_name, :value)
	  end
	end
end
