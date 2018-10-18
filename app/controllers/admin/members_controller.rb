module Admin
  class MembersController < BaseController
    load_and_authorize_resource

    def index
      @search_field = params[:search_field]
      @search_term = params[:search_term]
      @search_level = params[:search_level]
      if @search_level != "0" && !@search_level.nil?
        @order_member = Member.where(account_class: @search_level).search(field: @search_field, term: @search_term).page(params[:page]).per(200)
      else
        @order_member = Member.search(field: @search_field, term: @search_term).page(params[:page]).per(200)
      end
      @level1 = Member.where(account_class: "1").count
      @level2 = Member.where(account_class: "2").count
      @level3 = Member.where(account_class: "3").count

      @search_order = params[:search_order]
      if @search_order == "2"
        @members = @order_member.order("created_at desc")
      elsif @search_order == "3"
        @members = @order_member.order("created_at asc")
      else
        @members = @order_member.order("updated_at desc")
      end
    end

    def show
      @account_versions = AccountVersion.where(account_id: @member.account_ids).order(:id).reverse_order.page(params[:page]).per(200)
    end

    def edit
      @member = Member.find(params[:id])
    end

    def update
      @member = Member.find(params[:id])
      if @member.update_attributes(member_params)
        redirect_to admin_members_path
      else
        render :edit
      end
    end

    def toggle
      if params[:api]
        @member.api_disabled = !@member.api_disabled?
      else
        @member.disabled = !@member.disabled?
      end
      @member.save
    end

    def download_xlsx_account_version
      member_id = params[:member_id].to_i
      filename = "account_versions_member_#{member_id}" + Time.now.strftime("%Y/%m/%d %H:%M") + ".xlsx"
      @acc_versions = AccountVersion.where(member_id: member_id).order(:id)
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def active
      @member.update_attribute(:activated, true)
      @member.save
      redirect_to admin_member_path(@member)
    end

    private
      def member_params
        params.require(:member).permit(:role, :is_lock)
      end

  end
end
