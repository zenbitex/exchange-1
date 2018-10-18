module Private
  class DepositInfomationsController < BaseController
    before_action :auth_activated!
    before_action :auth_verified!
    before_action :two_factor_activated!
    
    def new
      @deposit_info = DepositInfomation.new
    end

    def create
      @deposit_info = DepositInfomation.new(:member_id => current_user.id)
      @deposit_info.assign_attributes deposit_info_params
      if @deposit_info.amount.nil?
        flash[:warning] = t('.failed')
        redirect_to deposit_infomation_path
      else
        if @deposit_info.amount > 0 && isInteger?(params[:deposit_infomation][:amount])
          if @deposit_info.save
          redirect_to settings_path, notice: t('.successfull')
          else
            flash[:warning] = t('.failed')
            redirect_to deposit_infomation_path
          end
        else
          flash[:warning] = t('.failed')
          redirect_to deposit_infomation_path
        end
      end     
    end

    private
    def deposit_info_params
      params.require(:deposit_infomation).permit(:payer_name, :amount, :memo, :date_deposit, :user_id)
    end
    def isInteger?(value)
      value =~ /^[-+]?[0-9]*$/ ? true : false
    end
  end
end