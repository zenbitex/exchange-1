module Admin
  class AffiliatesController < BaseController
    helper_method :sort_column, :sort_direction

    before_action :load_affiliate, only: :show
    before_action :check_params_search, only: [:index, :show]

    def index
      if params[:sort] == "number_people"
        @object = Affiliate.all
        @object.each do |object|
          object.update_attributes(number_people: Member.where(affiliate_member_id: object.member_id).count)
        end
        @history = Affiliate.order(sort_column + " " + sort_direction).page(params[:page]).per(Settings.admin.affiliate.page)
      else
        @history = Affiliate.order(sort_column + " " + sort_direction)
          .search_affiliate(field: @search_field, term: @search_term).page(params[:page])
          .per(Settings.admin.affiliate.page)
      end
    end

    def show
      @level1 = get_levels(@affiliate.member_id , "1")
      @level2 = get_levels(@affiliate.member_id , "2")
      @level3 = get_levels(@affiliate.member_id , "3")
      @level0 = Member.where(affiliate_member_id: @affiliate.member_id).count - (@level1 + @level2 + @level3)
      @search_level = params[:search_level]
      if @search_level != "0" && !@search_level.nil?
        @member_intro = Member.where(affiliate_member_id: @affiliate.member_id, account_class: @search_level)
          .search(field: @search_field, term: @search_term)
          .page(params[:page]).per(Settings.admin.affiliate.page)
      else
        @member_intro = Member.where(affiliate_member_id: @affiliate.member_id)
          .search(field: @search_field, term: @search_term).page(params[:page])
          .per(Settings.admin.affiliate.page)
      end
    end

    private
    def load_affiliate
      return if @affiliate = Affiliate.find_by(id: params[:id])
      flash[:error] = t ".not_found"
      redirect_to admin_affiliates_path
    end

    def check_params_search
      @search_field = params[:search_field]
      @search_term = params[:search_term]
    end

    def get_levels affiliate_member_id, level
      Member.where(affiliate_member_id: affiliate_member_id , account_class: level).count
    end

    def sort_table
      @history = if sort_column != :id
        if sort_direction == "desc"
          @history.sort_by {|k, v| v[sort_column]}.to_h
        else
          @history.sort_by {|k, v| v[sort_column]}.reverse.to_h
        end
      else
        if sort_direction == "desc"
          @history.sort.reverse.to_h
        else
          @history.sort.to_h
        end
      end
    end

    def sort_column
      Affiliate.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  end
end
