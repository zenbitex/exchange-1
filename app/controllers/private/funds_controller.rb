module Private
  class FundsController < BaseController
    layout 'funds'

    before_action :auth_activated!
    # before_action :auth_verified!
    # before_action :two_factor_activated!

    def index
      # binding.pry
      @deposit_channels = DepositChannel.all
      @withdraw_channels = WithdrawChannel.all
      @currencies = Currency.all.sort
      @accounts = current_user.accounts.where("currency != 1 and currency != 3")
      @deposits = current_user.deposits
      @withdraws = current_user.withdraws
      @fund_sources = current_user.fund_sources
      @banks = Bank.all
      @fees = FeeTrade.all
      @bank_account = BankAccount.where(member_id: current_user.id).last
      @deposit_mode = params["d"] ||= false
      @security = current_user.security || current_user.create_securities
      gon.jbuilder
    end

    def gen_address
      current_user.accounts.each do |account|
        next if not account.currency_obj.coin?

        if account.payment_addresses.blank?
          account.payment_addresses.create(currency: account.currency)
        else
          address = account.payment_addresses.last
          address.gen_address if address.address.blank?
        end
      end
      render nothing: true
    end

  end
end
