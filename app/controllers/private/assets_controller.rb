module Private
  class AssetsController < BaseController
    skip_before_action :auth_member!, only: [:index]

    def index
      @jpy_assets  = Currency.assets('jpy')
      @btc_proof   = Proof.current :btc
      @jpy_proof   = Proof.current :jpy
      @tao_proof   = Proof.current :tao
      @eth_proof   = Proof.current :eth
      @xrp_proof   = Proof.current :xrp

      if current_user
        @btc_account = current_user.accounts.with_currency(:btc).first
        @jpy_account = current_user.accounts.with_currency(:jpy).first
        @tao_account = current_user.accounts.with_currency(:tao).first
        @eth_account = current_user.accounts.with_currency(:eth).first
        @xrp_account = current_user.accounts.with_currency(:xrp).first
      end
    end

    def partial_tree
      account    = current_user.accounts.with_currency(params[:id]).first
      @timestamp = Proof.with_currency(params[:id]).last.timestamp
      @json      = account.partial_tree.to_json.html_safe
      respond_to do |format|
        format.js
      end
    end

  end
end
