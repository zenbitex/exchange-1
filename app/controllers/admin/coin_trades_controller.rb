module Admin
  class CoinTradesController < BaseController
    helper BuyCoinHelper
    def index
      @history = CoinTrade.all.order("created_at desc").page(params[:page]).per(200)
      search
    end

    private
    def search
      unless params[:coin_trade].blank?
        @history = CoinTrade.joins(:member)
                            .where(search_sql)
                            .order("created_at desc")
                            .page(params[:page])
                            .per(200)
      end
    end

    def search_sql
      case params_search[:field]
      when 'member_id'
        "member_id = '#{params_search[:search]}'"
      when 'email'
        "members.email LIKE '%#{params_search[:search]}%' "
      end
    end

    def params_search
      params.require(:coin_trade).permit(:field, :search)
    end
  end
end
