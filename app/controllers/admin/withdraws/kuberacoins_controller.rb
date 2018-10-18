module Admin
  module Withdraws
    class KuberacoinsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Kuberacoin'

      def index
        @one_kuberacoins = @kuberacoins.with_aasm_state(:accepted, :processing).order("id DESC")
        @all_kuberacoins = @kuberacoins.without_aasm_state(:accepted, :processing).order("id DESC")
      end

      def show
      end

      def update
        @kuberacoin.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @kuberacoin.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
