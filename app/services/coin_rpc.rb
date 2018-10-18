require 'net/http'
require 'uri'
require 'json'

class CoinRPC

  class JSONRPCError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  def initialize(uri)
    @uri = URI.parse(uri)
  end

  def self.[](currency)
    c = Currency.find_by_code(currency.to_s)
    if c && c.rpc
      name = c[:handler] || 'BTC'
      "::CoinRPC::#{name}".constantize.new(c.rpc)
    end
  end

  def method_missing(name, *args)
    handle name, *args
  end

  def handle
    raise "Not implemented"
  end

  class BTC < self
    def handle(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      raise ConnectionRefusedError
    end

    def safe_getbalance
      getbalance
    end
  end

  class Ethereum < self
    def method_missing(name, *args)
      args = args.nil? ? nil : args.first
      post_body = { 'method' => name, 'params' => args, 'jsonrpc' => '2.0', 'id' => 0 }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      resp['result']
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      http    = http.start
      request = Net::HTTP::Post.new(@uri.request_uri)
      # request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      ret = http.request(request).body
      http.finish
      return ret
    end

    def safe_getbalance
      begin
        address_eth = Currency.find_by_code('eth').address
        eth_getBalance([address_eth, "latest"]).to_i(16) / ((10**18)).to_d
      rescue
        'N/A'
      end
    end
  end

  class EthereumClassic < self
    def method_missing(name, *args)
      args = args.nil? ? nil : args.first
      post_body = { 'method' => name, 'params' => args, 'jsonrpc' => '2.0', 'id' => 0 }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      resp['result']
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      http    = http.start
      request = Net::HTTP::Post.new(@uri.request_uri)
      # request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      ret = http.request(request).body
      http.finish
      return ret
    end

    def safe_getbalance
      begin
        address_etc = Currency.find_by_code('etc').address
        eth_getBalance([address_etc, "latest"]).to_i(16) / ((10**18)).to_d
      rescue
        'N/A'
      end
    end
  end

  class KuberaCoin < self
    def method_missing(name, *args)
      args = args.nil? ? nil : args.first
      post_body = { 'method' => name, 'params' => args, 'jsonrpc' => '2.0', 'id' => 0 }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      resp['result']
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      http    = http.start
      request = Net::HTTP::Post.new(@uri.request_uri)
      # request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      ret = http.request(request).body
      http.finish
      return ret
    end

    def safe_getbalance
      begin
        string_bit = "0000000000000000000000000000000000000000000000000000000000000000"
        contract_address = Currency.find_by_code('kbr').address_contract
        address_kbr = Currency.find_by_code('kbr').address

        address_kbr_hex = address_kbr[2..-1]
        count_address_kbr_remain = 64 - address_kbr_hex.length
        address_kbr_bit = string_bit[0...count_address_kbr_remain] + address_kbr_hex
        data_balance = "0x70a08231" + address_kbr_bit
        balance_holding_address = CoinRPC['eth'].eth_call([{"to": contract_address, "data": data_balance}, "latest"])
        balance_holding_address.to_i(16)
      rescue
        'N/A'
      end
    end
  end

  class Ripple < self
    def method_missing(name, *args)
      args = args.nil? ? nil : args.first
      post_body = { 'method' => name, 'params' => args, 'jsonrpc' => '2.0', 'id' => 0 }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      resp['result']
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      http    = http.start
      request = Net::HTTP::Post.new(@uri.request_uri)
      # request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      ret = http.request(request).body
      http.finish
      return ret
    end

    def safe_getbalance
      begin
        address_ripple = Currency.find_by_code('xrp').address
        getbalance_ripple = account_info(["account": "#{address_ripple}", "strict": true, "ledger_index": "current", "queue": true])
        sum_hot = getbalance_ripple['account_data']['Balance'].to_f / (10**6)

        list_address = PaymentAddress.where(:currency => 5, :active_ripple => 1).map(&:address)
        list_address.each do |address|
          getbalance_ripple = account_info(["account": "#{address}", "strict": true, "ledger_index": "current", "queue": true])
          sum_hot = sum_hot + getbalance_ripple['account_data']['Balance'].to_f / (10**6)
        end
        sum_hot
      rescue
        'N/A'
      end
    end
  end

end
