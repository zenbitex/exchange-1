module Admin
  module Withdraws
    class TaocoinsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Taocoin'

      def index
        @one_taocoins = @taocoins.with_aasm_state(:accepted, :processing).order("id DESC")
        @all_taocoins = @taocoins.without_aasm_state(:accepted, :processing).order("id DESC")
      end

      def show
      end

      def update
        @taocoin.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @taocoin.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
