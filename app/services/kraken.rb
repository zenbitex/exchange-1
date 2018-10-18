require 'base64'
require 'securerandom'
require 'addressable/uri'
require 'hashie'

module Kraken
  class Client
    include HTTParty
    def initialize(api_key=nil, api_secret=nil, options={})
      @api_key      = api_key
      @api_secret   = api_secret
      @api_version  = options[:version] ||= '0'
      @base_uri     = options[:base_uri] ||= 'https://api.kraken.com'
      @book_code = {
        "btcjpy" => "XXBTZJPY",
        "xrpjpy" => "XXRPZJPY",
        "xrpbtc" => "XXRPXXBT"
      }
    end

    ###########################
    ###### Public Data ########
    ###########################
    def assets(opts={})
      get_public 'Assets'
    end

    def conver_assets_pair(pair)
      if !@book_code[pair].nil?
        pair = @book_code[pair]
      end
      pair
    end

    def conver_assets(assets)
      asset = case assets
              when 'btc'
                'xxbt'
              when 'xrp'
                'xxrp'
              else
                assets
              end
    end

    def asset_pairs(opts={})
      get_public 'AssetPairs', opts
    end

    # get lowest_buy  and highest_sell price -> lay gia thu 3 de tranh fails
    # fee: 10%
    def buy_sell_best(pair, fee)
      return if fee.nil?
      begin
        order_books = order_book(pair)
      rescue StandardError => bang
        MyLog.kraken("kraken error: #{bang}")
        return nil
      end

      if order_books.nil?
        return nil
      end

      order_books = order_books[@book_code[pair]]
      buy_order = order_books["bids"]
      if buy_order.kind_of?(Array) && buy_order.any?
        origin_buy_price = buy_order[0][0].to_f
        buy_order_price  = (buy_order[0][0].to_f / (1 - fee.to_f/100)).round(2)
        if pair == 'xrpbtc'
          buy_order_price = (buy_order[0][0].to_f / (1 - fee.to_f/100)).round(8)
        end
        buy_order_amount = buy_order[1][1].to_f
      else
        return nil
      end

      sell_order = order_books["asks"]
      if sell_order.kind_of?(Array) && sell_order.any?
        origin_sell_price = sell_order[0][0].to_f
        sell_order_price  = (sell_order[0][0].to_f * (1 - fee.to_f/100)).round(2)
        if pair == 'xrpbtc'
          sell_order_price  = (sell_order[0][0].to_f * (1 - fee.to_f/100)).round(8)
        end
        sell_order_amount = sell_order[0][1].to_f
      else
        return nil
      end

      result = {
        origin_buy_price: origin_buy_price,
        buy_order_price: buy_order_price,
        buy_order_amount: buy_order_amount,
        origin_sell_price: origin_sell_price,
        sell_order_price: sell_order_price,
        sell_order_amount: sell_order_amount
      }
    end

    def ticker(pairs) # takes string of comma delimited pairs
      opts = { 'pair' => pairs }
      get_public 'Ticker', opts
    end

    def order_book(pair, opts={})
      code = {
        "btcjpy" => "xbtjpy",
        "xrpjpy" => "xrpjpy",
        "xrpbtc" => "xrpxbt"
      }

      if !code[pair].nil?
        pair = code[pair]
      end

      opts['pair'] = pair
      get_public 'Depth', opts
    end

    def get_public(method, opts={})
      url = @base_uri + '/' + @api_version + '/public/' + method
      r = self.class.get(url, query: opts)
      hash = Hashie::Mash.new(JSON.parse(r.body))
      hash[:result]
    end

    ######################
    ##### Private Data ###
    ######################

    # https://www.kraken.com/en-us/help/api#withdraw-funds
    # Return
    # --refid |reference id
    def withdraw(asset, key_withdraw, amount)
      # FOR TEST
      # if asset == 'btc'
      #   return "AGBSEGO-O4CG6C-4ICXA5" #BTC
      # else
      #   return "AIBF6Q4-E3HGTN-RBLWZG" #XRP
      # end

      asset = conver_assets(asset)
      opts = {
        aclass: "currency",
        asset: asset,
        key: key_withdraw,
        amount: amount
      }
      MyLog.kraken("karaken-withdraw #{amount}#{asset} to #{key_withdraw}:")
      post_private 'Withdraw', opts
    end

    # Return:
    # --method  | name of the withdrawal method that will be used
    # --limit  |maximum net amount that can be withdrawn right now
    # --fee    |amount of fees that will be paid
    def withdraw_info(asset, key_withdraw, amount)
      # EX: opts={ aclass: "currency", asset: "XXRP", key: "BAP_VN", amount: "100000" }
      asset = conver_assets(asset)
      opts = {
        aclass: "currency",
        asset: asset,
        key: key_withdraw,
        amount: amount
      }
      post_private 'WithdrawInfo', opts
    end

    #EX: "xrp", "AIBF6Q4-E3HGTN-RBLWZG"
    def withdraw_status(asset, refid)
      asset = conver_assets(asset)
      opts = {
        aclass: "currency",
        asset: asset
      }
      MyLog.kraken('karaken-get-withdraw_status| refid: #{refid} | asset: #{asset}')
      status = post_private 'WithdrawStatus', opts
      return 'Fails' if status.size.zero? || status[0] == 'EQuery:Unknown asset'
      status.each do |s|
        return s['status'] if s['refid'] == refid
      end
      return 'Fails'
    end

    def balance(opts={})
      post_private 'Balance', opts
    end

    def trade_balance(opts={})
      post_private 'TradeBalance', opts
    end

    def open_orders(opts={})
      post_private 'OpenOrders', opts
    end

    # Success order
    def closed_orders(opts={})
      post_private 'ClosedOrders', opts
    end

    #"OZRUJT-3XJKM-7LFOLF"
    def query_orders(opts={})
      post_private 'QueryOrders', opts
    end

    # pending = order pending book entry
    # open = open order
    # closed = closed order
    # canceled = order canceled
    # expired = order expired
    def check_order_status(txid = 0)
      MyLog.kraken("kraken-checkorder-status| txid: #{txid}")
      txid = txid.to_s
      begin
        orders = query_orders ({txid: txid})
      rescue StandardError => _bang
        return false
      end

      begin
        status = orders[txid]['status']
      rescue StandardError => _bang
        return false
      end
      status
    end

    def trade_history(opts={})
      post_private 'TradesHistory', opts
    end
    #### Private User Trading ####

    def buy_sell(amount, price, type="buy", pair, expiretm)
      #FOR TEST
      # return "OHFBGN-7Q7BQ-37DKVJ"

      pair = conver_assets_pair(pair)
      MyLog.kraken("Kraken:  #{type} #{amount} #{pair}  vs price: #{price}")
      begin
        opts = {
          pair: pair, #'XBTJPY'
          type: type,
          ordertype: 'market',
          volume: amount,
          price: price,
          expiretm: expiretm
        }
        response = add_order(opts)
      rescue StandardError => bang
        MyLog.kraken("ERROR #{bang}*** Kraken:  #{type} #{amount} #{pair} vs price: #{price}")
        return {error: "StandardError"}
      end
      if response[0].is_a? String
        MyLog.kraken("ERROR ***#{response[0]}*** Kraken:  #{type} #{amount} #{pair} vs price: #{price}")
        return {error: response[0]}
      end
      order_id = response['txid']
    end

    def add_order(opts={})
      required_opts = %w{ pair type ordertype volume }
      leftover = required_opts - opts.keys.map(&:to_s)
      if leftover.length > 0
        raise ArgumentError.new("Required options, not given. Input must include #{leftover}")
      end
      post_private 'AddOrder', opts
    end

    def cancel_order(txid)
      opts = { txid: txid }
      post_private 'CancelOrder', opts
    end

    #######################
    #### Generate Signed ##
    ##### Post Request ####
    #######################

    private

      def post_private(method, opts={})
        opts['nonce'] = nonce
        post_data = encode_options(opts)

        headers = {
          'API-Key' => @api_key,
          'API-Sign' => generate_signature(method, post_data, opts)
        }

        url = @base_uri + url_path(method)
        r = self.class.post(url, { headers: headers, body: post_data }).parsed_response
        r['error'].empty? ? r['result'] : r['error']
      end

      # Generate a 64-bit nonce where the 48 high bits come directly from the current
      # timestamp and the low 16 bits are pseudorandom. We can't use a pure [P]RNG here
      # because the Kraken API requires every request within a given session to use a
      # monotonically increasing nonce value. This approach splits the difference.
      def nonce
        high_bits = (Time.now.to_f * 10000).to_i << 16
        low_bits  = SecureRandom.random_number(2 ** 16) & 0xffff
        (high_bits | low_bits).to_s
      end

      def encode_options(opts)
        uri = Addressable::URI.new
        uri.query_values = opts
        uri.query
      end

      def generate_signature(method, post_data, opts={})
        key = Base64.decode64(@api_secret)
        message = generate_message(method, opts, post_data)
        generate_hmac(key, message)
      end

      def generate_message(method, opts, data)
        digest = OpenSSL::Digest.new('sha256', opts['nonce'] + data).digest
        url_path(method) + digest
      end

      def generate_hmac(key, message)
        Base64.strict_encode64(OpenSSL::HMAC.digest('sha512', key, message))
      end

      def url_path(method)
        '/' + @api_version + '/private/' + method
      end
  end
end
