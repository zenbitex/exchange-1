module Admin
  class IdDocumentsController < BaseController
    load_and_authorize_resource

    def index
      @order_id_document = IdDocument.joins(:member)
                            .merge(Member.avail_member)
                            .where("(#{level}) and (#{search_field})")
                            .page(params[:page]).per(200)
      @level1 = Member.where(account_class: "1").count
      @level2 = Member.where(account_class: "2").count
      @level3 = Member.where(account_class: "3").count
      @search_order = params[:search_order]
      if @search_order == "2"
        @id_documents = @order_id_document.order("created_at desc")
      elsif @search_order == "3"
        @id_documents = @order_id_document.order("created_at asc")
      else
        @id_documents = @order_id_document.order("updated_at desc")
      end
    end

    def level
      @search_level = params[:search_level]
      case @search_level
        when "1"
          "members.account_class is null "
        when "2"
          "members.account_class = 1 "
        when "3"
          @post_card_search = true
          "members.account_class = 2 and (members.post_card = 0 or members.post_card is null) "
        when "4"
          @post_card_search = true
          "members.account_class = 2 and members.post_card = 1 "
        when "5"
          @post_card_search = true
          "members.account_class = 2 and members.post_card = 2 "
        when "6"
          @post_card_search = true
         "members.account_class = 2 and members.post_card = 3 "
        when "7"
          @post_card_search = true
          "members.account_class = 2 and members.post_card = 4 "
        when "8"
          "members.account_class = 3 "
        else
          "members.account_class is null or members.account_class >= 0 "
      end
    end

    def search_field
      @search_field = params[:search_field]
      return true if params[:search_term].blank?
      @search_term = params[:search_term]
      trim_space_input = params[:search_term].squish.delete(' ')
      if @search_field == "email"
        " members.email LIKE '%#{@search_term}%'"
      elsif @search_field == "member_id"
        " id_documents.member_id = #{@search_term}"
      else
        " REPLACE(REPLACE(id_documents.#{@search_field}, '　', ''), ' ', '') LIKE '%#{trim_space_input}%'"
      end
    end
    # postcard status(post_card field in member table)
    # 0/null: 書留未送付
    # 1: 書留到着待ち
    # 2: 不在
    # 3: 住所違い
    # 4: その他
    def set_postcard
      data_send = params[:data_send]
      data_success = []
      data_error = []
      postcard = Postcard.new
      postcard_type = data_send[0].to_i
      data_send.delete_at 0
      data_send.each do |user_id|
        member_id = user_id.to_i
        case postcard_type
        when 1
          if postcard.send_post_card member_id
            data_success.push user_id
          else
            data_error.push (user_id + "(エラー: #{postcard.error})")
          end
        else
          if Member.find_by(id: member_id).update_attribute(:post_card, postcard_type - 1)
            data_success.push user_id
          else
            data_error.push (user_id + "(データベースのエラー)")
          end
        end
      end
      render json: {data_success: data_success, data_error: data_error}
    end

    def show
      member = @id_document.member
      referrer_member_id = member.referrer_member_id
      @aff_code = nil
      if !referrer_member_id.nil?        
        @aff_code = Member.find(referrer_member_id).sn_code
      end

      @phone_verified = member.two_factors.by_type("sms")
      if member.account_class == 2 and member.post_card == 1 and member.order_postcard and member.order_postcard > 0
        postcard = Postcard.new
        @delivery_infor = postcard.get_delivery_infor member.order_postcard
      end
    end

    def edit
      referrer_member_id = Member.find(@id_document.member_id).referrer_member_id
      @code = nil;
      if !referrer_member_id.nil?
        @code = Member.find(referrer_member_id).sn_code
      end
    end

    def update_member_information
      sn_code = params[:referrer_code]
      if !sn_code.blank?
        member_referrer = Member.find_by(sn_code: sn_code)
        if member_referrer.nil?
          redirect_to edit_admin_id_document_path(@id_document), alert: "紹介コードが間違えました！"
          return
        else
          member = Member.find(@id_document.member_id)
          member.update_attributes(referrer_member_id: member_referrer.id)
        end
      end

      if @id_document.update_attributes id_document_params
        redirect_to admin_id_document_path(@id_document), notice: "変更しました！"
      else
        render :edit
      end
    end



    def download_xlsx_id_document
      @id_documents = IdDocument.all
      filename = "info_user_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_balance
      filename = "balances_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @members = Member.where.not(id: [1])
      @accounts = []
      @members.each do |m|
        balance_jpy = Account.where(member_id: m.id).where(currency: 1).pluck(:balance)
        balance_btc = Account.where(member_id: m.id).where(currency: 2).pluck(:balance)
        balance_tao = Account.where(member_id: m.id).where(currency: 3).pluck(:balance)
        balance_xrp = Account.where(member_id: m.id).where(currency: 5).pluck(:balance)
        @accounts << {
          member_id: m.id,
          name: m.display_name,
          jpy: balance_jpy[0].to_i,
          btc: balance_btc[0].to_f,
          tao: balance_tao[0].to_i,
          xrp: balance_xrp[0].to_f
        }
      end

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_bank_account
      @banks = BankAccount.all
      filename = "banks_account_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_address
      filename = "addrress_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @members = Member.all
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def download_xlsx_trade
      filename = "trade_" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @trades = Trade.where.not(ask_member_id: [8], bid_member_id: [8]).order("created_at ASC")

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end


    def send_mail_reject
      @message = {notice: t('.reject_user')}
      member_id = params[:id_document][:member_id].to_i
      reason_reject = params[:id_document][:reason_reject]
      member = IdDocument.find_by_member_id(member_id)

      if reason_reject == "inadequate_document"
        RejectUserMailer.inadequate_document_mail(member_id).deliver
        member.reason_reject = reason_reject
        member.save
        redirect_to :back, @message
      elsif reason_reject == "incomplete_input"
        RejectUserMailer.incomplete_input_mail(member_id).deliver
        member.reason_reject = reason_reject
        member.save
        redirect_to :back, @message
      elsif reason_reject == "image_unknown"
        RejectUserMailer.image_unknown_mail(member_id).deliver
        member.reason_reject = reason_reject
        member.save
        redirect_to :back, @message
      else
        redirect_to :back
      end
    end

    def update
      @message = {notice: "OK 完了しました"}
      @phone_verified = @id_document.member.two_factors.by_type("sms")
      if @id_document.member.activated?
        acc_level = 1
      end
      if params[:approve]
        @result = @id_document.approve!
        if !@id_document.foreign.nil? && @id_document.foreign.is?
          acc_level = 1
        elsif @phone_verified.activated?
          acc_level = 2
        end

        if @result
          TokenMailer.accepted(@id_document.member.email).deliver
        end
      elsif params[:reject]
        @result = @id_document.reject!
        acc_level = 1
        IdDocument.where(id: @id_document.id).update_all(is_address: 0)
      elsif params[:accepted]
        @result = IdDocument.where(id: @id_document.id).update_all(is_address: 1)
        if !@id_document.foreign.nil? && @id_document.foreign.is?
          acc_level = 1
        elsif @phone_verified.activated?
          acc_level = 3
        end
      elsif params[:reject_address]
        @result = IdDocument.where(id: @id_document.id).update_all(is_address: 0)
        if @phone_verified.activated?
          acc_level = 2
        else
          acc_level = 1
        end
      end

      if !@result
        @message = {alert: "ERROR, エラー"}
      end

      if !@id_document.member.activated?
        acc_level = nil
      end

      if @id_document.member.account_class != acc_level
        @id_document.member.update_attribute(:account_class, acc_level)
      end

      if acc_level == 3 && @id_document.member.bonus != 1
        admin_account = Account.find_by(:member_id => 1,:currency => 3)
        bonus_fund = 1000
        referrer_bonus_fund = 1500
        if admin_account.balance > bonus_fund

          referrer_member = Member.find_by(id: @id_document.member.referrer_member_id)
          if referrer_member
            #inviter
            referrer_member.accounts.find_by(:currency => 3).lock!.plus_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
            admin_account.lock!.sub_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil

            #invited
            @id_document.member.accounts.find_by(:currency => 3).lock!.plus_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
            admin_account.lock!.sub_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
          end

          admin_account.lock!.sub_funds bonus_fund, reason: Account::BONUS, ref: nil
          @id_document.member.accounts.find_by(:currency => 3).lock!.plus_funds bonus_fund, reason: Account::BONUS, ref: nil
          # send mail
          TaocoinMailer.bonus(@id_document.member.email).deliver
          # update bonus state
          @id_document.member.update_attribute(:bonus, 1)
        end
      end

      redirect_to admin_id_document_path(@id_document), @message
    end

    def send_bonus_for_old_user
      list_member_lv3 = Member.where(:account_class => 3, :bonus => nil)
      admin_account = Account.find_by(:member_id => 1,:currency => 3)
      if list_member_lv3.any?
        list_member_lv3.each do |member|
          if admin_account.balance > 1000
            # bonus
            admin_account.lock!.sub_funds 1000, reason: Account::BONUS, ref: nil
            member.accounts.find_by(:currency => 3).lock!.plus_funds 1000, reason: Account::BONUS, ref: nil
            # send mail
            TaocoinMailer.bonus(member.email).deliver
            # update bonus state
            member.update_attribute(:bonus, 1)
          end
        end
        redirect_to admin_id_documents_path, notice: "Send bonus successfull"
      else
        redirect_to admin_id_documents_path, alert: "Don't have any one to bonus"
      end
    end

    def set_level_all
      all_user = Member.all
      all_user.each do |user|
        set_level = nil
        set_level = 1 if user.activated?
        set_level = 2 if set_level == 1 && user.id_document_verified? && user.two_factors.by_type("sms").activated?
        set_level = 3 if set_level == 2 && user.id_document.is_address == 1
        set_level = 1 if set_level != nil && user.id_document.foreign && user.id_document.foreign.is?
        next if user.id_document && user.id_document.foreign.nil?
        user.update_attribute(:account_class, set_level) if user.account_class != set_level
      end
      redirect_to admin_id_documents_path, notice: "Update level all user successfull!!!"
    end

    def send_missing_bonus
      list_referrer_user = Member.where.not(:referrer_member_id => nil)
      list_received_bonus = list_referrer_user.where(:account_class => 3)
      admin_account = Account.find_by(:member_id => 1,:currency => 3)
      list_referrer_user_id = []
      list_received_bonus.each do |user|
        if admin_account.balance > 500
          admin_account.lock!.sub_funds 500, reason: Account::BONUS, ref: nil
          user.accounts.find_by(:currency => 3).lock!.plus_funds 500, reason: Account::INVITE_BONUS, ref: nil

          admin_account.lock!.sub_funds 500, reason: Account::BONUS, ref: nil
          Member.find(user.referrer_member_id).accounts.find_by(:currency => 3).lock!.plus_funds 500, reason: Account::INVITE_BONUS, ref: nil

          TaocoinMailer.bonus_missing(user.email).deliver
          list_referrer_user_id.push user.referrer_member_id
        end
      end
      list_referrer_user_id.uniq.each do |user|
        TaocoinMailer.bonus_missing(Member.find(user).email).deliver
      end
      redirect_to admin_id_documents_path, notice: "Send missing bonus successfull"
    end

    private


    def id_document_params
      params.require(:id_document).permit(:name, :birth_date, :country, :zipcode, :city, :address, :job_type, :trade_purpose, :id_document_type)
    end
  end
end
