module Admin
  class DashboardController < BaseController
    skip_load_and_authorize_resource

    def index
      redirect_to admin_id_documents_path if current_user.role > 1
      @daemon_statuses = Global.daemon_statuses
      @currencies_summary = Currency.all.map(&:summary)
      @register_count = Member.count
      @balance_summary_jpy = Account.where
      @accounts = Account.where.not(member_id: [1]).where(currency: "1")
      @balance = 0
      @accounts.each do |a|
        @balance += a.balance + a.locked
      end
      @balance = @balance.round(4)
    end

    def download_xlsx_balance_account
      filename = "balances_accounts_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @accounts_jpy = Account.where.not(member_id: [1]).where(currency: "1")
      @accounts_balance_jpy = []
      @accounts_jpy.each do |account|
      	member = Member.find_by_id(account.member_id)
        @accounts_balance_jpy << {
          member_id: member.id,
          name: member.display_name,
          email: member.email,
          balance: account.balance.round(4),
          locked: account.locked.round(4)
        }
      end

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_balance_account_31_7_2017
      filename = "balances_accounts_31_7_2017_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @account_balance = []
      all_member = Member.all
      all_currency = Currency.all

      all_member.each do |member|
        @balances = []
        all_currency.each do |currency|
          versions = AccountVersion.where("member_id = ? and currency = ? and created_at <= ?", member.id, currency.id , "2017-07-31 23:59:59").order("created_at DESC")
          if versions.present?
            balance = versions.first.amount
          else
            balance = 0
          end
          @balances << balance
        end
        @account_balance << {
          member_id: member.id,
          name: member.display_name,
          email: member.email,
          jpy_balance: @balances[0],
          btc_balance: @balances[1],
          tao_balance: @balances[2],
          xrp_balance: @balances[3],
          bch_balance: @balances[4]
        }
      end
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end
  end
end
