module Admin
  module Deposits
    class KuberacoinsController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Kuberacoin'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24 * 365)
        @kuberacoins = @kuberacoins.includes(:member).
          where('created_at > ?', start_at).
          order('id DESC').page(params[:page]).per(200)
      end

      def update
        @kuberacoin.accept! if @kuberacoin.may_accept?
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
