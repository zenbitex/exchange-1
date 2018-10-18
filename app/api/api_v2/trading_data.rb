module APIv2
  class TradingData < Grape::API
    helpers ::APIv2::NamedParams

    get "/config" do
      {
        supports_marks: false,
        supports_time: true,
        supports_search: true,
        supports_group_request: false,
        supported_resolutions: [
          "1",
          "5",
          "15",
          "30",
          "60",
          "120",
          "D",
          "W"
        ]
      }
    end

    get "time" do
      Time.now.to_i
    end

    desc 'Get ticker of specific market.'
    params do
      requires :symbol, type: String, desc: "symbols"
    end

    #https://github.com/tradingview/charting_library/wiki/Symbology
    get "symbols" do
      {
        name: params[:symbol],
        "exchange-traded" => "",
        "exchange-listed" => "",
        timezone: "Asia/Tokyo",
        minmov: 1,
        minmov2: 0,
        pointvalue: 1,
        session: "24x7",
        has_intraday: true,
        has_no_volume: true,
        description: "",
        type: "stock",
        supported_resolutions: [
          "1",
          "5",
          "15",
          "30",
          "60",
          "120",
          "D",
          "W"
        ],
        pricescale: 10 ** Market.find(params[:symbol].downcase)[:bid]["fixed"],
        ticker: params[:symbol]
      }
    end

    params do
      requires :symbol, type: String, desc: "ss"
      requires :resolution, type: String, desc: "1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 10080"
      requires :from, type: Integer, desc: "ss"
      requires :to, type: Integer, desc: "ss"
    end

    #{time, close, open, high, low, volume}
    get "history" do
      redis ||= KlineDB.redis
      minus = params[:resolution].to_i
      case params[:resolution]
        when "D"
          minus = 24 * 60
        when "W"
          minus = 7 * 24 * 60
        else
      end

      key = "exchangepro:#{params[:symbol].downcase}:k:#{minus}"

      first_ts = JSON.parse(redis.lindex(key, 0)).first
      last_ts = JSON.parse(redis.lindex(key, -1)).first

      from = (params[:from] > first_ts) ? params[:from] : first_ts
      to   = (params[:to] < last_ts) ? params[:to] : last_ts

      if from >= to
        data = {
          s: "no_data"
        }
        return data
      end

      diff = to - from
      distance = diff / (minus * 60)
      length = redis.llen(key)
      offset = [length - distance, 0].max
      js = JSON.parse('[%s]' % redis.lrange(key, offset, -1).join(','))

      t = []
      o = []
      h = []
      l = []
      c = []
      v = []
      js.each do |e|
        t << e[0]
        o << e[1]
        h << e[2]
        l << e[3]
        c << e[4]
        v << e[5]
      end

      data = {
        t: t,
        o: o,
        h: h,
        l: l,
        c: c,
        v: v,
        s: "ok"
      }
      data
    end

  end
end
