class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_user, :is_admin?, :current_market, :gon, :header_value
  before_action :set_timezone, :set_gon
  after_action :allow_iframe
  after_action :set_csrf_cookie_for_ng
  rescue_from CoinRPC::ConnectionRefusedError, with: :coin_rpc_connection_refused

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    flash[:error] = 'もう一度お願いします'
    redirect_to :back # Example method that will destroy the user cookies
  end

  # def handle_unverified_request
  #   flash[:error] = 'Kindly retry.'
  #   redirect_to :back
  # end

  private

  include SimpleCaptcha::ControllerHelpers
  include TwoFactorHelper

  #bonus 500KBR for use deposit > 0.1BTC
  def bonus_affiliate
    affiliate_members = Member.active.where("affiliate_member_id =?", current_user.id)
    admin = Member.find(1)

    achieved_inviter_lv = 0
    bonus_acc = 0
    curr_achieved_inviter_lv = current_user.achieved_inviter_lv.nil? ? 0 : current_user.achieved_inviter_lv

    if affiliate_members.size >= 1000
      achieved_inviter_lv = 1
      bonus_acc = 1 #BTC
    end
    if affiliate_members.size >= 10000
      achieved_inviter_lv = 2
      bonus_acc = 10 #BTC
    end

    if achieved_inviter_lv > curr_achieved_inviter_lv && (admin.accounts.find_by(:currency => 2).balance >= bonus_acc)
      current_user.accounts.find_by(:currency => 2).lock!.plus_funds bonus_acc, reason: Account::BONUS_AFFILIATE, ref: nil
      admin.accounts.find_by(:currency => 2).lock!.sub_funds bonus_acc, reason: Account::BONUS_AFFILIATE, ref: nil

      #mark this sent bonus
      current_user.achieved_inviter_lv = achieved_inviter_lv
      current_user.save
    end

    affiliate_members.each do |mem|
      next if mem.check_bonus_deposit
      if mem.deposit_sum(2) >= 0.1
        if admin.accounts.find_by(:currency => 11).balance >= 500
          current_user.accounts.find_by(:currency => 11).lock!.plus_funds 500, reason: Account::BONUS_AFFILIATE, ref: nil
          admin.accounts.find_by(:currency => 11).lock!.sub_funds 500, reason: Account::BONUS_AFFILIATE, ref: nil
          mem.check_bonus_deposit = true
          mem.save
        end
      end
    end

  end

  def currency
    "#{params[:ask]}#{params[:bid]}".to_sym
  end

  def current_market
    @current_market ||= Market.find_by_id(params[:market]) || Market.find_by_id(cookies[:market_id]) || Market.first
  end

  def redirect_back_or_settings_page
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to id_document_path
    end
  end

  def redirect_back_or_funds_page
    current_user ||= @member
    if cookies[:redirect_to].present?
      redirect_to cookies[:redirect_to]
      cookies[:redirect_to] = nil
    else
      redirect_to accounts_path
      # redirect_to funds_path
    end
  end

  def current_user
    return if session[:two_factors].nil?
    @current_user ||= Member.current = Member.enabled.where(id: session[:member_id]).first
  end

  def auth_member!
    unless current_user
      if params["controller"]
        if params["controller"].include?("private/order_bids") || params["controller"].include?("private/order_asks")
          json = Jbuilder.encode do |json|
                json.result false
                json.message I18n.t("private.markets.show.need_login")
               end
          render status: 500, json: json
          return false
        end
      end

      set_redirect_to
      redirect_to signin_path, alert: t('activations.new.login_required')
    end
  end

  def auth_activated!
    redirect_to settings_path, alert: t('private.settings.index.auth-activated') unless current_user.activated?
  end

  def auth_verified!
    unless current_user and current_user.id_document and current_user.id_document_verified?
      redirect_to settings_path, alert: t('private.settings.index.auth-verified')
    end
  end

  def auth_no_initial!
  end

  def auth_pass!
    redirect_to root_path if session[:member_id].nil?
  end

  def auth_anybody!
    redirect_to root_path if current_user
  end

  def auth_admin!
    redirect_to main_app.root_path unless is_admin?
  end

  def is_admin?
    current_user && current_user.admin?
  end

  def two_factor_activated!
    if not current_user.two_factors.where(type: "TwoFactor::App").activated?
      redirect_to verify_google_auth_path, notice: t('two_factors.auth.please_active_two_factor')
    end
  end

	def confirm_address?
		current_user.id_document.is_address?
	end

  def two_factor_auth_verified?
    return false if not current_user.two_factors.activated?
    return false if two_factor_failed_locked? && !simple_captcha_valid?

    two_factor = current_user.two_factors.by_type(params[:two_factor][:type])
    return false if not two_factor

    two_factor.assign_attributes params.require(:two_factor).permit(:otp)
    if two_factor.verify?
      clear_two_factor_auth_failed
      true
    else
      increase_two_factor_auth_failed
      false
    end
  end

  def two_factor_auth_verified_withdraw?
    return false if not current_user.two_factors.activated?

    two_factor = current_user.two_factors.by_type(params[:two_factor][:type])
    return false if not two_factor

    two_factor.assign_attributes params.require(:two_factor).permit(:otp)
    if two_factor.verify?
      clear_two_factor_auth_failed
      true
    else
      increase_two_factor_auth_failed
      false
    end
  end

  def captcha_invalid?
    two_factor_failed_locked? && !simple_captcha_valid?
  end

  def two_factor_failed_locked?
    failed_two_factor_auth > 10
  end

  def failed_two_factor_auth
    Rails.cache.read(failed_two_factor_auth_key) || 0
  end

  def failed_two_factor_auth_key
    "exchangepro:session:#{request.ip}:failed_two_factor_auths"
  end

  def increase_two_factor_auth_failed
    Rails.cache.write(failed_two_factor_auth_key, failed_two_factor_auth+1, expires_in: 1.month)
  end

  def clear_two_factor_auth_failed
    Rails.cache.delete failed_two_factor_auth_key
  end

  def set_timezone
    Time.zone = ENV['TIMEZONE'] if ENV['TIMEZONE']
  end

  def set_gon
    gon.env = Rails.env
    gon.local = I18n.locale
    gon.market = current_market.attributes
    gon.ticker = current_market.ticker
    gon.markets = Market.to_hash

    gon.pusher = {
      key:       ENV['PUSHER_KEY'],
      wsHost:    ENV['PUSHER_HOST']      || 'api.pusherapp.com',
      wsPort:    ENV['PUSHER_WS_PORT']   || '80',
      wssPort:   ENV['PUSHER_WSS_PORT']  || '443',
      encrypted: ENV['PUSHER_ENCRYPTED'] == 'true'
    }

    gon.clipboard = {
      :click => I18n.t('actions.clipboard.click'),
      :done => I18n.t('actions.clipboard.done')
    }

    gon.i18n = {
      brand: I18n.t('gon.brand'),
      ask: I18n.t('gon.ask'),
      bid: I18n.t('gon.bid'),
      cancel: I18n.t('actions.cancel'),
      latest_trade: I18n.t('private.markets.order_book.latest_trade'),
      switch: {
        notification: I18n.t('private.markets.settings.notification'),
        sound: I18n.t('private.markets.settings.sound')
      },
      notification: {
        title: I18n.t('gon.notification.title'),
        enabled: I18n.t('gon.notification.enabled'),
        new_trade: I18n.t('gon.notification.new_trade')
      },
      time: {
        minute: I18n.t('chart.minute'),
        hour: I18n.t('chart.hour'),
        day: I18n.t('chart.day'),
        week: I18n.t('chart.week'),
        month: I18n.t('chart.month'),
        year: I18n.t('chart.year')
      },
      chart: {
        price: I18n.t('chart.price'),
        volume: I18n.t('chart.volume'),
        open: I18n.t('chart.open'),
        high: I18n.t('chart.high'),
        low: I18n.t('chart.low'),
        close: I18n.t('chart.close'),
        candlestick: I18n.t('chart.candlestick'),
        line: I18n.t('chart.line'),
        zoom: I18n.t('chart.zoom'),
        depth: I18n.t('chart.depth'),
        depth_title: I18n.t('chart.depth_title')
      },
      place_order: {
        confirm_submit: I18n.t('private.markets.show.confirm'),
        confirm_cancel: I18n.t('private.markets.show.cancel_confirm'),
        price: I18n.t('private.markets.place_order.price'),
        volume: I18n.t('private.markets.place_order.amount'),
        sum: I18n.t('private.markets.place_order.total'),
        price_high: I18n.t('private.markets.place_order.price_high'),
        price_low: I18n.t('private.markets.place_order.price_low'),
        full_bid: I18n.t('private.markets.place_order.full_bid'),
        full_ask: I18n.t('private.markets.place_order.full_ask')
      },
      trade_state: {
        new: I18n.t('private.markets.trade_state.new'),
        partial: I18n.t('private.markets.trade_state.partial')
      }
    }

    gon.currencies = Currency.all.inject({}) do |memo, currency|
      memo[currency.code] = {
        code: currency[:code],
        symbol: currency[:symbol],
        isCoin: currency[:coin]
      }
      memo
    end
    # gon.fiat_currency = Currency.where(:coin => false).first.code

    gon.tickers = {}
    Market.all.each do |market|
      gon.tickers[market.id] = market.unit_info.merge(Global[market.id].ticker)
    end

    if current_user
      gon.current_user = { sn: current_user.sn }
      gon.accounts = current_user.accounts.inject({}) do |memo, account|
        memo[account.currency] = {
          currency: account.currency,
          balance: account.balance,
          locked: account.locked
        } if account.currency_obj.try(:visible)
        memo
      end
    end
  end

  def coin_rpc_connection_refused
    render 'errors/connection'
  end

  def save_session_key(member_id, key)
    Rails.cache.write "exchangepro:sessions:#{member_id}:#{key}", 1, expire_after: ENV['SESSION_EXPIRE'].to_i.minutes
  end

  def clear_all_sessions(member_id)
    if redis = Rails.cache.instance_variable_get(:@data)
      redis.keys("exchangepro:sessions:#{member_id}:*").each {|k| Rails.cache.delete k.split(':').last }
    end

    Rails.cache.delete_matched "exchangepro:sessions:#{member_id}:*"
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options' if Rails.env.development?
  end

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || form_authenticity_token == request.headers['X-XSRF-TOKEN']
  end

  def header_value
    market = Market.find("btcjpy")
    price = market.ticker
    sell = price[:sell].to_f
    buy = price[:buy].to_f
    exchange_price = price[:last].to_f
    if current_user
      btc_balance = current_user.accounts.find_by_currency(2).balance.to_f
      jpy_balance = current_user.accounts.find_by_currency(1).balance.to_f
      return {
        "sell" => sell,
        "buy" => buy,
        "price" => exchange_price,
        "btc" => btc_balance,
        "jpy" => jpy_balance
      }
    else
      return {
        "sell" => sell,
        "buy" => buy,
        "price" => exchange_price
      }
    end
  end

  def coin_price market
    market = Market.find(market)
    price = market.ticker
    exchange_price = price[:last].to_f
  end

end
