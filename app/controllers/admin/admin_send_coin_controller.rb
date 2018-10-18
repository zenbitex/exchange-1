module Admin
  class AdminSendCoinController < BaseController
    skip_load_and_authorize_resource
    def index
      @emails = Member.pluck(:email)
      @history = Sendcoin.where("user_id_source=?",1).order("id desc").page(params[:page]).per(20)
    end

    def send_coin
      if params[:email].blank? || params[:amount].blank?
        redirect_to admin_admin_send_coin_index_path, alert: "ちゃんと入力してください！"
        return
      end

      send_amount = params[:amount].to_f
      targer = Member.find_by_email(params[:email])
      admin_account = Account.find_by(:member_id => 1,:currency => 3)

      if targer.nil?
        redirect_to admin_admin_send_coin_index_path, alert: "ユーザーが見つからないです!"
        return
      end

      if admin_account.balance < send_amount
        redirect_to admin_admin_send_coin_index_path, alert: "AdminのTAOが足りませんです. 残り分： #{admin_account.balance}!"
        return
      end

      admin_account.lock!.sub_funds send_amount, reason: Account::SEND_COIN, ref: nil
      targer.accounts.find_by(:currency => 3).lock!.plus_funds send_amount, reason: Account::SEND_COIN, ref: nil

      Sendcoin.create(
        user_id_source: 1,
        user_id_destination: targer.id,
        amount: send_amount,
        email: params[:email],
        currency: 3
      )

      redirect_to admin_admin_send_coin_index_path, notice: "#{params[:email]}に#{send_amount}TAOを送った "
    end

    def email_exits
      # binding.pry
      if Member.find_by_email(params[:email])
        render :json => {success: true}, status: 200
      else
        render :json => {success: false}, status: 200
      end
    end
  end
end
