module CronJob
  class CoincheckRate
    def self.fetch_rate
      data = {}
      ["btc", "eth","etc", "xrp", "bch"].each do |currency|
        url_last = "https://coincheck.com/api/rate/#{currency}_jpy"
        response = HTTParty.get(url_last)
        price = response.parsed_response["rate"].to_f
        data[currency] = price
      end
      data["jpyt"] = 1
      #kbr
      url_last = "https://api.coinmarketcap.com/v1/ticker/kubera-coin/"
      response = HTTParty.get(url_last)
      price = response.parsed_response.first["price_btc"].to_f
      data["kbr"] = price * data["btc"]

      Rails.cache.write "coincheck-price", data
    end
  end
end
