module APIv2
  module Helpers

    def authenticate!
      current_user or raise AuthorizationError
    end

    # Please check expired time
    def jwt_token_authen!
      data = jwt_verify(headers["Token"])
      return  error!('401 Unauthorized', 401) if data.nil?
    end

    def json_fails message, http_code = 401
      error!({
         status: -1,
         message: message
         }, http_code)
    end

    def json_success(options = {})
      status 200
      result = {
        "status": 1
      }
      result.merge(options)
    end

    def curr_member
      data = jwt_verify(headers["Token"])
      Member.find data[:member_id]
    end

    def jwt_sign member_id
      claims = {
        member_id: member_id,
        expire_in: (Time.now + 7.days).to_i
      }
      JsonWebToken.sign(claims, {alg: 'HS256', key: ENV['JWT_SECRET']})
    end

    def jwt_verify jwt_token
      begin
        data = JsonWebToken.verify(jwt_token, key: ENV['JWT_SECRET'])
        return nil if data[:ok].empty?
        data[:ok]
      rescue => e
        nil
      end
    end

    def redis
      @r ||= KlineDB.redis
    end

    def current_user
      @current_user ||= current_token.try(:member)
    end

    def current_token
      @current_token ||= env['api_v2.token']
    end

    def current_market
      @current_market ||= Market.find params[:market]
    end

    def time_to
      params[:timestamp].present? ? Time.at(params[:timestamp]) : nil
    end

    def build_order(attrs)
      klass = attrs[:side] == 'sell' ? OrderAsk : OrderBid

      order = klass.new(
        source:        'APIv2',
        state:         ::Order::WAIT,
        member_id:     current_user.id,
        ask:           current_market.base_unit,
        bid:           current_market.quote_unit,
        currency:      current_market.id,
        ord_type:      attrs[:ord_type] || 'limit',
        price:         attrs[:price],
        volume:        attrs[:volume],
        origin_volume: attrs[:volume]
      )
    end

    def create_order(attrs)
      order = build_order attrs
      Ordering.new(order).submit attrs["market"]
      order
    rescue
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug order.inspect
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def build_order_app(attrs, member_id)
      klass = attrs[:side] == 'sell' ? OrderAsk : OrderBid

      order = klass.new(
        source:        'APIv2',
        state:         ::Order::WAIT,
        member_id:     member_id,
        ask:           current_market.base_unit,
        bid:           current_market.quote_unit,
        currency:      current_market.id,
        ord_type:      attrs[:ord_type] || 'limit',
        price:         attrs[:price],
        volume:        attrs[:volume],
        origin_volume: attrs[:volume]
      )
    end

    def create_order_app(attrs, member_id)
      order = build_order_app attrs, member_id
      Ordering.new(order).submit attrs["market"]
      order
    rescue
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug order.inspect
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def create_orders(multi_attrs)
      orders = multi_attrs.map {|attrs| build_order attrs }
      Ordering.new(orders).submit
      orders
    rescue
      Rails.logger.info "Failed to create order: #{$!}"
      Rails.logger.debug $!.backtrace.join("\n")
      raise CreateOrderError, $!
    end

    def order_param
      params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
    end

    def format_ticker(ticker)
      { at: ticker[:at],
        ticker: {
          buy: ticker[:buy],
          sell: ticker[:sell],
          low: ticker[:low],
          high: ticker[:high],
          last: ticker[:last],
          vol: ticker[:volume]
        }
      }
    end

    def get_k_json
      key = "exchangepro:#{params[:market]}:k:#{params[:period]}"

      if params[:timestamp]
        ts = JSON.parse(redis.lindex(key, 0)).first
        offset = (params[:timestamp] - ts) / 60 / params[:period]
        offset = 0 if offset < 0

        JSON.parse('[%s]' % redis.lrange(key, offset, offset + params[:limit] - 1).join(','))
      else
        length = redis.llen(key)
        offset = [length - params[:limit], 0].max
        if key == "exchangepro:xrpbtc:k:1"
          offset = 10510
        end
        JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))
      end
    end

    def get_k_json_app
      key = "exchangepro:#{params[:market]}:k:#{params[:period]}"

      if params[:timestamp]
        ts = JSON.parse(redis.lindex(key, 0)).first
        offset = (params[:timestamp] - ts) / 60 / params[:period]
        offset = 0 if offset < 0
        convert_json_point JSON.parse('[%s]' % redis.lrange(key, offset, offset + params[:limit] - 1).join(','))
      else
        length = redis.llen(key)
        offset = [length - params[:limit], 0].max
        if key == "exchangepro:xrpbtc:k:1"
          offset = 10510
        end
        convert_json_point JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))
      end
    end

    def convert_json_point array_point
      key_point = [:time, :open, :shadowH, :shadowL, :close]
      arr = []
      array_point.each do |i|
        i.pop
        arr << Hash[key_point.zip(i)]
      end
      return  arr
    end

    def gen_address member
      member.accounts.each do |account|
        next if not account.currency_obj.coin?

        if account.payment_addresses.blank?
          account.payment_addresses.create(currency: account.currency)
        else
          address = account.payment_addresses.last
          address.gen_address if address.address.blank?
        end
      end
    end

    def json_error message
      status 400
      {
        "success" => false,
        "results" => [
          {
            "errorCode" => 400,
            "errorMessage" => message
          }
        ]
      }
    end
  end
end
