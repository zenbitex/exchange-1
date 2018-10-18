module Admin
  class CountOrdersController < BaseController

    def index
      if !params[:from].present? || !params[:to].present?
        flash.now[:alert] = "【統計】開始日付又は終了日付を選択してください。"
      else
        date_from = DateTime.parse(params[:from])
        date_to = DateTime.parse(params[:to])
        if date_from <= date_to
          @orders = Order.where("created_at >= ? AND created_at <= ?", date_from.beginning_of_day, date_to.end_of_day)
          @count_order_ask = @orders.where(:type => 'OrderAsk').count
          @count_order_bid = @orders.where(:type => 'OrderBid').count
          @count_transaction = @orders.where(:state => 200).count
        else
          flash.now[:alert] = "【統計】終了日付に誤りがあります。"
        end
      end
    end
  end
end
