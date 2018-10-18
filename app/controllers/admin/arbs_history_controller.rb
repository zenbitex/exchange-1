module Admin
	class ArbsHistoryController < BaseController
    def index
      @arbs_history = ArbHistory.all.order("created_at desc").page(params[:page]).per(200)
    end

    def show
      user_arb = Arb.select(:tao_amount).find_by_member_id(params[:id])
      @current_tao = user_arb[:tao_amount].to_i
      @user_profit = ArbProfit.find_by_member_id(params[:id])
      @history = ArbHistory.where(:member_id => params[:id]).page(params[:page]).per(50)
    end

    def profit_index
      @arb_profit = ArbProfit.all.order("tao_profit desc").page(params[:page]).per(50)
      if !params["search"].nil? && !params["search"].empty?
        @arb_profit = ArbProfit.search(params["search"]).order("tao_profit desc").page(params[:page]).per(50)
      end
      @admin_jpy = admin_jpy_balance
    end

    def count_profit
      staff = [180, 236, 590, 573, 243, 9, 149, 8, 46, 155]
      list_member_id = ArbHistory.all.distinct.pluck(:member_id)
      list_member = Member.where(:id => list_member_id)
      list_member.each do |member|
        next if staff.include? member.id
        current_user_arb_history = member.arb_histories.where(created_at: (Time.now - 1.month).beginning_of_month..(Time.now - 1.month).end_of_month)
        first_point = member.arb_histories.where('created_at <= ?', (Time.now - 2.month).end_of_month).last


        # is there any history in last month
        if first_point
          current_point = first_point.current_tao_arb
        else
          current_point = 0
        end

        # beginning_of_month (first point)
        day = 1
        profit = 0

        # count profit to last_point
        current_user_arb_history.each do |point|
          profit += current_point * (point.created_at.day - day)
          day = point.created_at.day
          current_point = point.current_tao_arb
        end

        # last point to end_of_month
        profit += current_point * ((Time.now - 1.month).end_of_month.day - day + 1)

        # save database
        if member.arb_profit
          member.arb_profit.update_attributes(:tao_profit => profit)
        else
          member.create_arb_profit(:tao_profit => profit)
        end
      end

      # count percent
      sum = ArbProfit.where('member_id not in (?)', staff).sum(:tao_profit)
      all_arb_profit = ArbProfit.all
      all_arb_profit.each do |arb_profit|
        if staff.include? arb_profit.member_id
          arb_profit.update_attributes(:profit_percent => 0)
          next
        end
        percent = arb_profit.tao_profit * 100 / sum
        arb_profit.update_attributes(:profit_percent => percent)
      end

      redirect_to admin_arbprofit_path, notice: "Update successful"
    end

    def share_profit
      if params[:sum_profit].to_i >= admin_jpy_balance
        redirect_to admin_arbprofit_path, alert: "Admin JPY Balance not enough !"
        return
      end

      if params[:sum_profit].to_i < 1000
        redirect_to admin_arbprofit_path, alert: "Sum profit must be greater or equal 1000"
      else
        sum_profit = params[:sum_profit].to_i
        arb_profits = ArbProfit.all
        staff = [180, 236, 590, 573, 243, 9, 149, 8, 46, 155]
        arb_profits.each do |arb_profit|
          if staff.include? arb_profit.member_id
            arb_profit.update_attributes(:weight_profit => 0)
            next
          end
          profit = (sum_profit * arb_profit.profit_percent / 100).round
          arb_profit.update_attributes(:weight_profit => profit)
        end
        redirect_to admin_arbprofit_path, notice: "Share profit successful"
      end
    end

    def download_xls_arb_profit
      if params[:date].blank?
        redirect_to admin_arbprofit_path, alert: "日付を入力してください！"
        return
      end
      arb_date = Time.parse(params[:date])
      filename = "arb_profit_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @profit = AccountVersion
                .includes(:member)
                .where("member_id != ? AND reason = ? and created_at BETWEEN ? and ?", 1, 3001, arb_date.beginning_of_month, arb_date.end_of_month)
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xls_arb_profit_by_month
      @staff = [180, 236, 590, 573, 243, 9, 149, 8, 46, 155, 1]
      if params[:date].blank?
        redirect_to admin_arbprofit_path, alert: "日付を入力してください！"
        return
      end
      arb_date = Time.parse(params[:date])
      filename = "arb_profit_by_month_" + Time.now.strftime("%m/%Y %H:%M") + ".xlsx"
      @profit = ArbHistory.includes(:member)
                .where("member_id not in (?) AND created_at BETWEEN ? and ?", @staff, arb_date.beginning_of_month, arb_date.end_of_month)
      get_profit_by_month arb_date
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def send_profit
      arb_profits = ArbProfit.all
      admin_account = Account.find_by(:member_id => 1, :currency => 1)
      arb_profits.each do |arb_profit|
        next if arb_profit.weight_profit.nil? || arb_profit.weight_profit <= 0 || admin_account.balance < arb_profit.weight_profit
        current_user_account = arb_profit.member.accounts.find_by(:currency => 1)
        admin_account.lock!.sub_funds arb_profit.weight_profit, reason: Account::SEND_PROFIT, ref: nil
        current_user_account.lock!.plus_funds arb_profit.weight_profit, reason: Account::SEND_PROFIT, ref: nil
        ArbMailer.send_profit(arb_profit.member_id, arb_profit.weight_profit.to_i).deliver
        arb_profit.update_attributes(:weight_profit => 0)
      end
      redirect_to admin_arbprofit_path, notice: "Send profit successful"
    end

    private

    def get_profit_by_month time
      list_member_id = ArbHistory.all.distinct.pluck(:member_id)
      list_member = Member.where(:id => list_member_id)
      @member_with_profit = Hash.new
      sum_profit = 0
      list_member.each do |member|
        next if @staff.include? member.id
        current_user_arb_history = member.arb_histories.where(created_at: time.beginning_of_month..time.end_of_month)
        first_point = member.arb_histories.where('created_at <= ?', (time - 1.month).end_of_month).last

        # is there any history in last month
        if first_point
          current_point = first_point.current_tao_arb
        else
          current_point = 0
        end

        # beginning_of_month (first point)
        day = 1
        profit = 0

        # count profit to last_point
        current_user_arb_history.each do |point|
          profit += current_point * (point.created_at.day - day)
          day = point.created_at.day
          current_point = point.current_tao_arb
        end

        # last point to end_of_month
        profit += current_point * ((Time.now - 1.month).end_of_month.day - day + 1)
        @member_with_profit[member] = profit
        sum_profit += profit
      end
        #caculator profit by all member
        @member_with_profit = @member_with_profit.reduce({}){ |hash, (key, value)| hash.merge(key => ((value.to_f * 100 / sum_profit).round(3)))}
    end

    def admin_jpy_balance
      Member.find(1).accounts[0].balance
    end

  end
end
