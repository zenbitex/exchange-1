#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end
Rails.logger = logger = Logger.new STDOUT

contract_address = Currency.find_by_code("kbr").address_contract
$id_filter = CoinRPC['eth'].eth_newFilter(["address": contract_address])
logger.info "create filter"
logger.debug $id_filter

def filter
  #Create filter to receive notify when pending transaction arrive
  Rails.logger = logger = Logger.new STDOUT
  arr_ts_pending = CoinRPC['eth'].eth_getFilterChanges(["#{$id_filter}"])
  # logger.info "Array pending transaction"
  # logger.debug arr_ts_pending
  if !arr_ts_pending.empty?
  	logger.info arr_ts_pending
    arr_ts_pending.each do |detail|
    	amount = detail["data"].to_i(16)
      address_to = "0x" + detail["topics"][2][26..-1]
	    logger.info "OK OK"
	    payload = {txid: detail["transactionHash"], amount: amount, address_to: address_to}
	    attrs = {persistent: true}
	    AMQPQueue.enqueue(:deposit_kbr, payload, attrs)
    end
  end
end

while($running) do

  filter

  sleep 2
  # logger.info "Uninstall filter"
  # CoinRPC['eth'].eth_uninstallFilter(["#{id_filter}"])
end
