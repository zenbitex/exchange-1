module Admin
  class DepositInfomationsController < BaseController
    load_and_authorize_resource
    def index
      @search_field = params[:search_field]
      @search_term = params[:search_term]
      @deposit_informations = DepositInfomation.search(field: @search_field, term: @search_term).page params[:page]
    end
    def show
    end
    def update
      deposit_information = DepositInfomation.find(params[:id])
      message = {notice: "OK 完了しました"}
      if params[:approve]
        result = deposit_information.approve!
      end

      if params[:reject]
        result = deposit_information.reject!
      end
      if !result
        message = {alert: "ERROR, エラー"}
      end

      redirect_to admin_deposit_infomations_path, message
    end
  end
end