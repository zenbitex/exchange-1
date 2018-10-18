module Admin
  class FeeTradesController < BaseController
  def index
    @fees = FeeTrade.all
    @credit_price = CreditSetupPrice.new
    @market_type = ["btcjpy", "xrpjpy"]

    # fee_tao = FeeTrade.where(:currency => 3)
  #       fee_trade_tao = fee_tao[0]['amount'].to_f
  #       binding.pry
  end
  def credit_price
    data = params.require(:credit_setup_price).permit(:market, :enable, :price )
    CreditSetupPrice.where(market: data[:market]).destroy_all
    market = CreditSetupPrice.create!(data)
    flash[:success] = "Setup price finis"
    redirect_to :back
  end

  def new
    @currencies_summary = Currency.all.map(&:summary)
    @currencies_summary.each do |c|
        if !c[:coinable]
          @currencies_summary.delete(c)
        end
    end
    @fee = FeeTrade.new
    @currencies_summary.push({name: "CreditCard"})
    @fee_type = ["Deposit/Withdraw", "CreditCard"]
  end

  def create
    @fee = FeeTrade.new(fee_params)
    @f = FeeTrade.where(:currency => @fee.currency)
    if @f == []
      if @fee.save
        redirect_to admin_fee_trades_path
      else
        flash[:error] = "Opp, have an error, please try again!"
        redirect_to :back
      end
    else
      flash[:error] = "Currency is exits, cann't add"
      redirect_to :back
    end
  end

  def edit
      @fee = FeeTrade.find(params[:id])
  end

  def update
    @fee = FeeTrade.find(params[:id])
    if @fee.update(fee_params)
      flash[:note] = "Update successfully"
      redirect_to admin_fee_trades_path
    else
      flash[:error] = "Update Error"
      render :edit
    end
  end

  def download_xlsx_fee
    filename = "fees_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"

    @export_fee = []
    all_currency = Market.all
    @fees = []
    if params[:start_date].present? && params[:end_date].present?
      start = params[:start_date].split('-')
      end_ = params[:end_date].split('-')
      start_date = Date.new(start[0].to_i, start[1].to_i, start[2].to_i)
      end_date = Date.new(end_[0].to_i, end_[1].to_i, end_[2].to_i)

      if start_date <= end_date
        (start_date..end_date).map do |date|
          @fee_by_currency = []
          @sum_fee = 0
          all_currency.each do |currency|
            trades = Trade.where("currency = ? and created_at >= ? AND created_at <= ?", currency.code, date.beginning_of_day, date.end_of_day)
            if trades.present?
              trades.each do |trade|
                unless trade.fee.nil?
                  @sum_fee += trade.fee
                end
              end
            else
              @sum_fee = 0
            end
            @fee_by_currency << @sum_fee
            @sum_fee = 0
          end
          @export_fee << {
            date: date,
            sum: @fee_by_currency
          }
        end
      else
        redirect_to admin_fee_trades_path, alert: " 【手数料報告】終了日付に誤りがあります。"
      end
    else
      redirect_to admin_fee_trades_path, alert: " 【手数料報告】開始日付又は終了日付を選択してください。"
    end
    respond_to do |format|
      format.html
      format.xlsx {
        response.headers['Content-Disposition'] = 'attachment; filename=' + filename
      }
    end
  end

  private
    def fee_params
      params.require(:fee_trade).permit(:currency, :amount, :fee_type)
    end
  end
end
