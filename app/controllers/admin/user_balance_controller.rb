module Admin
  class UserBalanceController < BaseController
    helper_method :sort_column, :sort_direction

    def index
      search
    end
    def download_xlsx_user_balance
      filename = "user_balances_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @user_balances = Account.all.includes(:member, :payment_addresses)

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end
    private



    def search
      @search_content = params[:search][:content_search].gsub("\t", '').gsub(" ",'') if params[:search]
      if @search_content.blank?
        @members = Member.select(:id, :email).order("id ASC").includes(:accounts)
      else
        sql = if @search_content.to_i != 0
          "id = #{@search_content.to_i}"
        else
          "email LIKE '%#{@search_content}%'"
        end
        @members = Member.includes(:accounts).where(sql)
      end
      get_money if @members.size > 0
      sort_table if @user_balance
      pagging
      render :index
    end

    def pagging
      @members = if @user_balance
        Member.by_ids(@user_balance.keys).select(:id).page(params[:page]).per Settings.admin.user_balance.page
      else
        @members.page(params[:page]).per Settings.admin.user_balance.page
      end

      @user_balance = if params[:page]
        page_per = (params[:page].to_i - 1) * Settings.admin.user_balance.page - 1
        page_per_next = page_per + Settings.admin.user_balance.page
        @user_balance.to_a[page_per + 1..page_per_next].to_h
      else
        @user_balance.to_a[0..Settings.admin.user_balance.page - 1].to_h
      end
    end

    def get_money
      @user_balance = {}
      money = [:jpy, :btc, :tao, :xrp, :bcc]
      @members.each do |member|
        balances = member.accounts
        index = 0
        data = {}
        for money_account in balances
          data[money[index]] = money_account.balance.to_f
          index += 1
        end
        @user_balance[member.id] = data
        @user_balance[member.id][:email] = member.email
      end
    end

    def sort_email
      if sort_direction == "asc"
        @user_balance.sort_by {|k, v| v[sort_column].to_s}.to_h
      else
        @user_balance.sort_by {|k, v| v[sort_column].to_s}.reverse.to_h
      end
    end

    def sort_table
      @user_balance = if sort_column != :id
        if sort_column != :email
          if sort_direction == "asc"
            @user_balance.sort_by {|k, v| v[sort_column].to_f.to_d}.to_h
          else
            @user_balance.sort_by {|k, v| v[sort_column].to_f.to_d}.reverse.to_h
          end
        else
          sort_email
        end
      else
        if sort_direction == "asc"
          @user_balance.sort.reverse.to_h
        else
          @user_balance.sort.to_h
        end
      end
    end

    def sort_column
      if params[:sort]
        column = [:id, :email, :jpy, :btc, :tao, :xrp, :bcc]
        column.include?(params[:sort].to_sym) ? params[:sort].to_sym : :email
      else
        :id
      end
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  end
end
