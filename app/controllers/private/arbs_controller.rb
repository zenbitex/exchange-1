module Private
  class ArbsController < BaseController
    before_action :auth_activated!
    def index
      @arb = current_user.arb || current_user.create_arb
      @taocoin = current_user.arb.tao_amount.to_i
      @rate = ExchangeRates.find_by_currency("jpy").rate
      @tao_amount = current_user.accounts.find_by_currency(3).balance.to_i
      @day = count_day(current_user)

      if current_user.arb_profit
        start_point = Date.today.ago(1.month).beginning_of_month
        end_point = Date.today.end_of_month
        temp = AccountVersion.where('member_id=? AND reason=? AND created_at BETWEEN ? AND ?',current_user.id,AccountVersion::REASON_CODES[Account::SEND_PROFIT], start_point, end_point).last
        if temp.nil?
          @last_profit = 0
        else
          @last_profit = temp.balance   
        end
      end
      
    end

    def edit
      @arb = current_user.arb || current_user.create_arb
    end

    def create
      @arb = current_user.arb
      admin_account = Account.find_by(:member_id => 1,:currency => 3)
      user_account = current_user.accounts.find_by_currency(3)
      user_tao_amount = user_account.balance

      if params[:arb][:tao_amount].to_i > user_account.balance
        redirect_to arbs_path, alert: t('.insufficient_fund')
      elsif params[:arb][:tao_amount] <= 0
        redirect_to arbs_path, alert: t('.invalid_amount')
      else
        if @arb.nil?
          @arb = current_user.create_arb arb_params
        else
          new_amount = @arb.tao_amount + params[:arb][:tao_amount].to_i
          @arb.update_attributes :tao_amount => new_amount
        end

        user_account.lock!.sub_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil
        admin_account.lock!.plus_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil

        save_arbs_history(current_user.id, 'deposit', params[:arb][:tao_amount], new_amount)
        # user_profit(params[:arb][:tao_amount], "deposit")

        redirect_to arbs_path, notice: t('.deposit_successful')
      end
    end

    def update
      @arb = current_user.arb
      admin_account = Account.find_by(:member_id => 1,:currency => 3)
      user_account = current_user.accounts.find_by_currency(3)
      user_tao_amount = user_account.balance
      if params[:withdraw]
        if params[:arb][:tao_amount].nil? || @arb.tao_amount.nil?
          redirect_to arbs_path, alert: t('.insufficient_fund')
        else
          # if params[:arb][:tao_amount].to_i < 0
          #   redirect_to arbs_path, alert: t('.insufficient_fund')
          if !isInteger?(params[:arb][:tao_amount])
            redirect_to arbs_path, alert: t('.tao_amount_integer')
          elsif params[:arb][:tao_amount].to_i > @arb.tao_amount
            redirect_to arbs_path, alert: t('.insufficient_fund')
          elsif params[:arb][:tao_amount].to_i <= 0
            redirect_to arbs_path, alert: t('.invalid_amount')
          elsif params[:arb][:tao_amount].to_i == @arb.tao_amount

            user_account.lock!.plus_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil
            admin_account.lock!.sub_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil

            save_arbs_history(current_user.id, 'withdraw', params[:arb][:tao_amount], 0)
            # user_profit(params[:arb][:tao_amount], "withdraw")

            @arb.destroy
            redirect_to arbs_path, notice: t('.withdraw_successful')
          else
            new_amount = @arb.tao_amount - params[:arb][:tao_amount].to_i
            @arb.update_attributes :tao_amount => new_amount

            user_account.lock!.plus_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil
            admin_account.lock!.sub_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil

            save_arbs_history(current_user.id, 'withdraw', params[:arb][:tao_amount], new_amount)
            # user_profit(params[:arb][:tao_amount], "withdraw")

            redirect_to arbs_path, notice: t('.withdraw_successful')
          end
        end
      else
        if params[:arb][:tao_amount].to_i > user_account.balance
          redirect_to arbs_path, alert: t('.insufficient_fund')
        elsif params[:arb][:tao_amount].to_i <= 0
          redirect_to arbs_path, alert: t('.invalid_amount')
        else
          if @arb.tao_amount.nil?
            new_amount = params[:arb][:tao_amount].to_i
          else
            new_amount = @arb.tao_amount + params[:arb][:tao_amount].to_i
          end
          @arb.update_attributes :tao_amount => new_amount

          user_account.lock!.sub_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil
          admin_account.lock!.plus_funds params[:arb][:tao_amount].to_i, reason: Account::ARB, ref: nil

          save_arbs_history(current_user.id, 'deposit', params[:arb][:tao_amount], new_amount)
          # user_profit(params[:arb][:tao_amount], "deposit")

          redirect_to arbs_path, notice: t('.deposit_successful')
        end
      end
    end

    private

    def user_profit(tao_amount, type)
      x = ArbHistory.profit_month(current_user.id)
      count_day = x.count
      if type == "deposit"
        if count_day == 1
          tao_profit = x[0].current_tao_arb
          weight_profit = tao_profit
          save_arb_profit(current_user.id, tao_profit, weight_profit)        
        elsif count_day >= 2
          arb_profit_user = ArbProfit.find_by_member_id(current_user.id)
          weight_user = arb_profit_user.weight_profit
          day_profit = x[-1].created_at.day - x[-2].created_at.day
          weight_profit = weight_user + x[-1].tao_amount
          if day_profit == 0
            tao_profit = weight_profit
          else
            tao_profit = weight_profit + weight_profit * day_profit
          end

          arb_profit_user.weight_profit = weight_profit
            arb_profit_user.tao_profit    = tao_profit
            arb_profit_user.save
        end
      elsif type == "withdraw"
        arb_profit_user = ArbProfit.find_by_member_id(current_user.id)
        weight_user = arb_profit_user.weight_profit
        day_profit = x[-1].created_at.day - x[-2].created_at.day
        weight_profit = weight_user - x[-1].tao_amount
        if day_profit == 0
          tao_profit = weight_profit
        else
          tao_profit = weight_profit + weight_profit * day_profit
        end

        arb_profit_user.weight_profit = weight_profit
        arb_profit_user.tao_profit    = tao_profit
        arb_profit_user.save  
      end  
    end

    def arb_params
      params.required(:arb).permit(:tao_amount)
    end

    def isInteger?(value)
      value =~ /^[-+]?[0-9]*$/ ? true : false
    end

    def save_arbs_history(member_id, type, tao_amount, current_tao_arb)
      ArbHistory.create(
        member_id: current_user.id,
        type_arb: type,
        tao_amount: tao_amount,
        current_tao_arb: current_tao_arb
      )
    end

    def save_arb_profit(member_id, tao_profit, weight_profit)
      ArbProfit.create(
        member_id: member_id,
        tao_profit: tao_profit,
        weight_profit: weight_profit
      )        
    end

    def update_all_current_tao_arb
      x = Arb.all
      x.each do |x|
        update_current_tao_arb(x.member_id)
      end
    end

    def update_current_tao_arb(current_member_id)
      user_arb_all = ArbHistory.where("member_id = ?", current_member_id)
      user_arb = Array.new
      user_arb_all.each do |u|
        if u.current_tao_arb.nil?
          user_arb << u
        end
      end
      if !user_arb.blank?
        count_user_arb = user_arb.count
        user_arb[0].current_tao_arb = user_arb[0].tao_amount      
        user_arb[0].save
        for i in 1...count_user_arb
          if user_arb[i].type_arb == "deposit"
            user_arb[i].current_tao_arb = user_arb[i-1].current_tao_arb + user_arb[i].tao_amount
            user_arb[i].save
          elsif user_arb[i].type_arb == "withdraw"
            user_arb[i].current_tao_arb = user_arb[i-1].current_tao_arb - user_arb[i].tao_amount
            user_arb[i].save
          end
        end
      end     
    end

    def count_day(current_user)
      current_user_arb_history = current_user.arb_histories.where(created_at: Time.now.beginning_of_month..Time.now.end_of_month)
      first_point = current_user.arb_histories.where('created_at <= ?', (Time.now - 1.month).end_of_month).last

      # is there any history in last month
      if first_point && first_point.current_tao_arb != 0
        current_point = 1
      else
        current_point = 0
      end

      # beginning_of_month (first point)
      day = 1
      sum_day = 0
      # count sum_day to last_point
      current_user_arb_history.each do |point|
        sum_day += current_point * (point.created_at.day - day)
        day = point.created_at.day
        if point.current_tao_arb == 0
          current_point = 0
        else
          current_point = 1
        end
      end
      # last point to now
      sum_day += current_point * (Time.now.day - day)
      return sum_day
    end
  end
end
