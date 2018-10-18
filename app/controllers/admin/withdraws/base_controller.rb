module Admin
  module Withdraws
    class BaseController < ::Admin::BaseController
      before_action :find_withdraw, only: [:show, :update, :destroy]
      before_action :ensure_hot_wallet_balance, only: [:update]

      def channel
        @channel ||= WithdrawChannel.find_by_key(self.controller_name.singularize)
      end

      def kls
        channel.kls
        #binding.pry
      end

      def find_withdraw
        w = channel.kls.find(params[:id])
        self.instance_variable_set("@#{self.controller_name.singularize}", w)
        if w.may_process? and (w.amount > w.account.locked)
          flash[:alert] = 'TECH ERROR !!!!'
          redirect_to action: :index
        end
      end

      def ensure_hot_wallet_balance
        w = Withdraw.find_by_id(params[:id])
        if w.amount >= CoinRPC[w.currency].safe_getbalance
          flash[:alert] = 'お金が足りないです'
          redirect_to action: :index
        end
      end
    end
  end
end
