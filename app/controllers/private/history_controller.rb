module Private
  class HistoryController < BaseController

    helper_method :tabs

    def account
      @market = current_market

      @deposits = Deposit.where(member: current_user).with_aasm_state(:accepted)
      @withdraws = Withdraw.where(member: current_user).with_aasm_state(:done)

      @transactions = (@deposits + @withdraws).sort_by {|t| -t.created_at.to_i }
      @transactions = Kaminari.paginate_array(@transactions).page(params[:page]).per(200)
    end

    def trades
      @trades = current_user.trades.includes(:ask_member).includes(:bid_member).order('id desc').page(params[:page]).per(200)
    end

    def orders
      @orders = current_user.orders.includes(:trades).order("id desc").page(params[:page]).per(200)
    end

    def cloudsafe
      account_id = current_user.accounts.find_by(:currency => 3).id
      @taocoin_trades = TaocoinTrades.where(:account_id => account_id).order("id desc").page(params[:page]).per(200)
    end

    def sendcoin
      account_id = current_user.id
      @user_source = Member.find_by(:id => account_id)
      @user_source = @user_source.email

      @sendcoins = Sendcoin.where(:user_id_source => account_id).order("id desc").page(params[:page]).per(200)

    end

    def receivecoin
      account_id = current_user.id
      @user_des = Member.find_by(:id => account_id)
      @user_des = @user_des.email

      @receivecoins = Sendcoin.where(:user_id_destination => account_id).order("id desc").page(params[:page]).per(200)

    end

    private

    def tabs
      {
        order: ['header.order_history', order_history_path, "fa-shopping-cart"],
        trade: ['header.trade_history', trade_history_path, "fa-suitcase"],
        sendcoin: ['header.sendcoin_history', sendcoin_history_path, "fa-paper-plane"],
        receivecoin: ['header.receivecoin_history', receivecoin_history_path, "fa-download"],
      }
    end

  end
end
