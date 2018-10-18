require 'timeout'
module Admin
  class ManageServersController < BaseController

    def index
      @currencies = Currency.all
    end

    def server_detail
      code = params['server']
      @server = {}
      flag = false
      block = 0
      currency = Currency.find_by_code(code).key.upcase
      general_address = Currency.find_by_code(code).address
      quick_withdraw_max = Currency.find_by_code(code).quick_withdraw_max.to_f
      rpc = Currency.find_by_code(code).rpc
      begin
        case code
        when 'btc'
          status = Timeout::timeout(2) {
            block = CoinRPC['btc'].getblockcount
            flag = true
          }
        when 'eth'
          status = Timeout::timeout(2) {
            block = CoinRPC['eth'].eth_blockNumber.to_i(16)
            flag = true
          }
        when 'xrp'
          status = Timeout::timeout(2) {
            CoinRPC['xrp'].server_info()
            flag = true
            block = nil
          }
        when 'etc'
          status = Timeout::timeout(2) {
            block = CoinRPC['etc'].eth_blockNumber.to_i(16)
            flag = true
          }
        when 'bch'
          status = Timeout::timeout(2) {
            block = CoinRPC['bch'].getblockcount
            flag = true
          }
        when 'kbr'
          status = Timeout::timeout(2) {
            block = CoinRPC['kbr'].eth_blockNumber.to_i(16)
            flag = true
          }
        end
      rescue
        flag = false
        block = nil
      end
      @server = {server: currency, general_address: general_address, quick_withdraw_max: quick_withdraw_max, rpc: rpc, block: block, flag: flag}
    end

  end
end
