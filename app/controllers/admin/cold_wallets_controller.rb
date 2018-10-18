module Admin 
  class ColdWalletsController < BaseController
    skip_load_and_authorize_resource

    def index
      @cold_wallets = ColdWallet.all
      @currencies_summary = Currency.all.map(&:summary)
      @currencies_summary.each do |c|
        if !c[:coinable]
          @currencies_summary.delete(c)
        end
      end
      @cold_wallet = ColdWallet.new
    end

    def new
    end

    def create
      cold_wallet_params["fee"] = cold_wallet_params["fee"].to_f
      cold_wallet_params["amount"] = cold_wallet_params["amount"].to_f
      @cold_wallet = ColdWallet.new(cold_wallet_params)
      if @cold_wallet.validate_address?
        if @cold_wallet.save
          @cold_wallet.sendtocoldwallet
          if @cold_wallet.errors.any?
            redirect_to admin_cold_wallets_path, alert: @cold_wallet.errors.full_messages.join(', ')
          else
            redirect_to admin_cold_wallets_path
          end
        else
          redirect_to admin_cold_wallets_path, alert: @cold_wallet.errors.full_messages.join(', ')
        end
      else
        redirect_to admin_cold_wallets_path, alert: @cold_wallet.errors.full_messages.join(', ')
      end
    end

    private
    def cold_wallet_params
      params.require(:cold_wallet).permit(:currency, :address, :amount, :fee)
    end
  end
end
