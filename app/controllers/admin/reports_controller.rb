module Admin
  class ReportsController < BaseController
    skip_load_and_authorize_resource

    def index
    end

    def download_xlsx_export_price
      filename = "export_price_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      all_market = Market.all
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【価格報告】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        @prices = []
        if day_start <= day_end
          (day_start..day_end).each do |date|
            @price = []
            all_market.each do |market|
              trades = Trade.where('currency = ? and created_at <= ?', market.code, date.end_of_day).order("created_at DESC")
              if trades.present?
                last_price = trades.first.price
              else
                last_price = 0
              end
              @price << last_price
            end
            @prices << {
              date: date,
              price: @price
            }
          end
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【価格報告】終了日付に誤りがあります。"
        end
      end
    end

    def download_xlsx_export_balance
      filename = "export_balance_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      all_member = Member.all
      @balances = []
      if !params[:date_select].present?
        redirect_to admin_reports_path, alert: " 【残高報告】日付を選択してください。"
      else
        date_select = DateTime.parse(params[:date_select])
        all_member.each do |member|
          balance = member.accounts.order("currency ASC").pluck("currency","balance", "locked").map { |e|
            if Currency.ids.include?(e[0])
              e[1] + e[2]
            else
              0
            end
          }
          @balances << {
            member_id: member.id,
            email: member.email,
            balances: balance
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

    def download_xlsx_trade_fee

      filename = "trade_fee_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      if !params[:start_fee].present? || !params[:end_fee].present?
        redirect_to admin_reports_path, alert: " 【手数料報告】開始日付又は終了日付を選択してください。"
      else
        start_fee = params[:start_fee].split('-')
        end_fee = params[:end_fee].split('-')
        start_date_fee = Date.new(start_fee[0].to_i, start_fee[1].to_i, start_fee[2].to_i)
        end_date_fee = Date.new(end_fee[0].to_i, end_fee[1].to_i, end_fee[2].to_i)
        if start_date_fee <= end_date_fee
          @trades = Trade.includes(:bid_member, :ask_member)
            .where.not("ask_member_id = ? AND bid_member_id = ?", 8, 8)
            .where("created_at >= ? AND created_at <= ?", start_date_fee.beginning_of_day, end_date_fee.end_of_day)
            .order("created_at ASC")
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【手数料報告】終了日付に誤りがあります。"
        end
      end
    end

    def download_xlsx_withdraw_history
      filename = "withdraw_history_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @all_currency = Currency.all
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        if day_start <= day_end
          @all_withdraw = Withdraw.where(:aasm_state => 'done').where('updated_at between ? and ?',day_start.beginning_of_day, day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
      end
    end

    def download_xlsx_deposit_history
      filename = "deposit_history_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @all_currency = Currency.all
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        if day_start <= day_end
          @all_deposit = Deposit.where(:aasm_state => 'accepted').where('updated_at between ? and ?',day_start.beginning_of_day, day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
      end
    end

    def download_xlsx_order_ask_history
      filename = "order_ask_history_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        if day_start <= day_end
          @orders = Order.where(type: "OrderAsk").where('created_at between ? and ?',day_start.beginning_of_day, day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
      end
    end

    def download_xlsx_order_bid_history
      filename = "order_bid_history_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        if day_start <= day_end
          @orders = Order.where(type: "OrderBid").where('created_at between ? and ?',day_start.beginning_of_day, day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
      end

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_trade_history
      filename = "trade_history_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @all_market = Market.all
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        day_start = DateTime.parse(params[:start])
        day_end = DateTime.parse(params[:end])
        if day_start <= day_end
          @trades = Trade.all.where('created_at between ? and ?',day_start.beginning_of_day, day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
      end

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_order_cancel_history
      filename = "order_cancel_history_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      if !params[:start].present? || !params[:end].present?
        redirect_to admin_reports_path, alert: " 【送金履歴】開始日付又は終了日付を選択してください。"
      else
        @day_start = DateTime.parse(params[:start])
        @day_end = DateTime.parse(params[:end])
        if @day_start <= @day_end
          @orders_cancel = Order.where(state: 0).where('created_at between ? and ?', @day_start.beginning_of_day, @day_end.end_of_day)
          respond_to do |format|
            format.html
            format.xlsx {
              response.headers['Content-Disposition'] = 'attachment; filename=' + filename
            }
          end
        else
          redirect_to admin_reports_path, alert: " 【送金履歴】終了日付に誤りがあります。"
        end
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
