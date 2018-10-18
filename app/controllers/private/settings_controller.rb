module Private
  class SettingsController < BaseController
  	before_action :create_bank_account
    before_action :create_missing_account
    def index
      unless current_user.activated?
        flash.now[:info] = t('.activated')
      end
      @id_document_state = current_user.id_document.aasm_state
      redirect_to accounts_path
    end

    def create_bank_account
    	if !current_user.bank_account
    		current_user.create_bank_account
    	end
    end

    def create_missing_account
      if current_user.accounts.count != Currency.all.count
        current_user.touch_accounts
      end
    end

    def generate_sn
        sn = "Rip#{ROTP::Base32.random_base32(30)}ple"
    end
  end
end

