module Admin
  class ReferralDiagramController < BaseController
    skip_load_and_authorize_resource

    def index
      @search_email = Member.all
      member = Member.find_by_email(params[:search_email])
      if member
        create_data_diagram(member_root: member.id)
      end
    end

    def create_data_diagram(member_root: nil)
      # member_root = parent_id
      parent_id = member_root
      array = []
      member_ref = Member.where(referrer_member_id: parent_id)
      # member_id = member_ref.pluck("id")
      member_ref.each do |m|
        array << {parent: parent_id.to_s, email: m.email, key: m.id.to_s}
      end

      array.each do |a|
        member_children = Member.where(referrer_member_id: a[:key])
        if member_children
          search_ref_member(member_id: a[:key], array: array)
        end
      end
      member = Member.find_by_id(member_root)
      if member.referrer_member_id
        parent_member = Member.find_by_id(member.referrer_member_id)
        array << {key: parent_member.id, email: parent_member.email}
        array << {key: member_root, parent: parent_member.id, email: member.email}
      end
      # binding.pry
      gon.source = array
    end

    def search_ref_member(member_id: nil, array: nil)
      member_ref = Member.where(referrer_member_id: member_id)
      member_ref.each do |m|
        array << {parent: member_id.to_s, email: m.email, key: m.id.to_s}
      end
      array
    end

  end
end
