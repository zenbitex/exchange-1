module Private
  class BankAccountsController < BaseController
    def new
      @bank_account = BankAccount.where(member_id: current_user.id).last
      if @bank_account
        redirect_to bank_accounts_show_path
        return
      end 
      @bank_account = BankAccount.new
    end

    def edit
      @bank_account = BankAccount.where(member_id: current_user.id).last
      if params[:back_page]
        @@back_page = params[:back_page].gsub! '$', '#'
        @back_page = @@back_page
      else 
        @@back_page = bank_accounts_show_path
        @back_page = bank_accounts_show_path
      end
    end

    def create
      @bank_account = BankAccount.new(:member_id => current_user.id)
      params[:bank_account][:account_number] = params[:bank_account][:account_number].zen_to_han
      @bank_account.assign_attributes bank_account_params
      if @bank_account.save
        redirect_to settings_path, notice: t('.notice')
      else
        render :new
      end
    end

    def update
      @bank_account = BankAccount.where(member_id: current_user.id).last
      params[:bank_account][:account_number] = params[:bank_account][:account_number].zen_to_han
      if @bank_account.update_attributes bank_account_params
        if @@back_page != nil
          redirect_to @@back_page, notice: t('.notice')
        else 
          redirect_to settings_path, notice: t('.notice')
        end
      else
        render :edit
      end
    end

    def show
      @bank_account = BankAccount.where(member_id: current_user.id).last
    end

    private

    def bank_account_params
      params.require(:bank_account).permit(:bank_name, :bank_branch, :account_type, :account_number, :owner)
    end
  end
end
