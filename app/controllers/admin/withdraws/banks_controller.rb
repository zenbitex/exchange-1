module Admin
  module Withdraws
    class BanksController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Bank'

      def index
        @one_banks = @banks.with_aasm_state(:accepted, :processing).order("id DESC") # bank is choice
        @all_banks = @banks.without_aasm_state(:accepted, :processing).order("id DESC") # list banks
        @chanel = channel
      end

      def show
      end

      def update
        if @bank.may_success_jpy?
          @bank.success_jpy!
        end

        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @bank.reject!
        redirect_to :back, notice: t('.notice')
      end

      def download_xlsx_withdraw_jpy_history
        @withdraws = Withdraw.where(:currency => 1, :aasm_state => "done")
        redirect_to admin_withdraws_banks_path, alert: "Don't have any withdraw transaction done" if @withdraws.empty?
        
        filename = "withdraw_jpy_history_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"

        respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
      end
    end
  end
end
