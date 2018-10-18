module Private
  class AffiliatesController < ApplicationController
    before_action :auth_member!, :gen_affiliate_code, :bonus_affiliate
    helper_method :email_censor

    def index
      affiliate_users = Member.active.where("affiliate_member_id = ?", current_user.id)
      @affiliate_count_user = affiliate_users.count
      @affiliate_users = affiliate_users.page(params[:page]).per(20)
      @bonus_kbr = current_user.account_versions.where("reason = ? and currency = ?", 999, 11).sum(:balance).to_i
      @bonus_btc = current_user.account_versions.where("reason = ? and currency = ?", 999, 2).sum(:balance)

      @target_percent = @affiliate_count_user.to_f / 100
    end

    def download_xls_affiliate_proof
      filename = "affiliate_proof_" + Time.now.strftime("%d/%m/%Y %H:%M") + ".xlsx"
      @proof = Member.where(affiliate_member_id: current_user.id).order("id desc")

      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename=' + filename
        }
      end
    end

    def email_censor email
      len = email.size
      return "#{email[0,3]}**********#{email[len-3,len]}"
    end

    private
    def check_account!
      redirect_to settings_path, alert: t('private.settings.index.affiliate') unless current_user.account_class == 3
    end

    def gen_affiliate_code
      return if current_user.affiliate_code.present?
      begin
        affiliate_code = SecureRandom.hex(8)
      end while Member.where(:affiliate_code => affiliate_code).any?
      current_user.update_attributes(:affiliate_code => affiliate_code)
    end
  end
end
