# ActionController::Base are used by both Exchangepro controllers and
# Doorkeeper controllers.
class ActionController::Base

  before_action :set_language

  private

  def set_language
    cookies[:lang] = params[:lang] unless params[:lang].blank?
    locale = cookies[:lang] || "ja"
    I18n.locale = locale if locale && I18n.available_locales.include?(locale.to_sym)
    # binding.pry
  end

  def set_redirect_to
    if request.get?
      uri = URI(request.url)
      cookies[:redirect_to] = "#{uri.path}?#{uri.query}"
    end
  end

end
