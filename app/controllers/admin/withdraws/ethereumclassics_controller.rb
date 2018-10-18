module Admin
  module Withdraws
    class EthereumclassicsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Ethereumclassic'

      def index
        @one_ethereumclassics = @ethereumclassics.with_aasm_state(:accepted, :processing).order("id DESC")
        @all_ethereumclassics = @ethereumclassics.without_aasm_state(:accepted, :processing).order("id DESC")
      end

      def show
      end

      def update
        @ethereumclassic.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @ethereumclassic.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
