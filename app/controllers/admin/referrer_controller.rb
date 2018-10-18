module Admin
  class ReferrerController < BaseController
    def index
      @members = Member.select('id, email, referrer_member_id').where.not(referrer_member_id: 0).order("id ASC").page(params[:page]).per(200)
      @referrer_list = []
      get_referrer
      @referrer_list.sort_by {|value| value[:referrer_email]}
    end
    def search

      content_search = params["search"]["content_search"]
      if !content_search
        flash[:notice] = 'エラー'
        render :index
      end
      if content_search.to_i != 0
        sql = "id = #{content_search.to_i} and referrer_member_id != 0"
        sql1 = "referrer_member_id = #{content_search.to_i}"
      else 
        sql = "email = '#{content_search}' and referrer_member_id != 0"
        id_user = Member.select('id').find_by(email: content_search)
        if id_user
          sql1 = "referrer_member_id = #{id_user.id}"
        else 
          sql1 = nil
        end
      end

      @members = Member.select('id, email, referrer_member_id').where(sql).order("id ASC").page(params[:page]).per(200)
      referrer1 = get_referrer

      if sql1
        @members = Member.select('id, email, referrer_member_id').where(sql1).order("id ASC").page(params[:page]).per(200)
        get_referrer
        @referrer_list.concat referrer1
      end

      if @referrer_list.size > 0
        @referrer_list = @referrer_list.sort_by {|value| value[:referrer_email]}
        flash[:notice] = "ユーザー: '#{content_search}'"
        render :index
      else 
        flash[:notice] = 'ユーザーが見つかりません。'
        render :index
      end
      
    end

    def get_referrer
      @referrer_list = []
      for member in @members
        referrer_email =  Member.select('email', 'id').find_by(id: member[:referrer_member_id])
        if referrer_email
          data = {id: member.id, email: member.email, referrer_id: referrer_email.id, referrer_email: referrer_email.email}
          @referrer_list.push data
        end
      end
      @referrer_list
    end
  end
end