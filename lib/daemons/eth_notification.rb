#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require 'rubygems'
require 'websocket-client-simple'
require 'json'
require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end
Rails.logger = logger = Logger.new STDOUT

$id_filter = CoinRPC['eth'].eth_newPendingTransactionFilter
logger.info "create filter"
logger.debug $id_filter

def filter
  #Create filter to receive notify when pending transaction arrive
  Rails.logger = logger = Logger.new STDOUT
  user_eth_address = PaymentAddress.where(currency: 4).where.not(address: nil).pluck(:address)
  user_kbr_address = PaymentAddress.where(currency: 11).where.not(address: nil).pluck(:address)
  arr_ts_pending = CoinRPC['eth'].eth_getFilterChanges(["#{$id_filter}"])
  # logger.info "Array pending transaction"
  # logger.debug arr_ts_pending
  if !arr_ts_pending.empty?
    arr_ts_pending.each do |tx|
      address_receipt = CoinRPC['eth'].eth_getTransactionByHash([tx])
      if address_receipt && address_receipt["to"].in?(user_eth_address)
        logger.info "OK OK"
        payload = {txid: tx}
        attrs = {persistent: true}
        AMQPQueue.enqueue(:deposit_eth, payload, attrs)
      elsif address_receipt && address_receipt["to"].in?(user_kbr_address)
        logger.info "ETH send TOKEN"
        payload = {txid: tx}
        attrs = {persistent: true}
        AMQPQueue.enqueue(:send_kbr, payload, attrs)
      end
    end
  end
end

while($running) do

  begin
    filter
  rescue
    CoinRPC['eth'].eth_uninstallFilter(["#{$id_filter}"])
    $id_filter = CoinRPC['eth'].eth_newPendingTransactionFilter
    logger.info "create filter again"
    logger.debug $id_filter
  end

  sleep 5
  # logger.info "Uninstall filter"
  # CoinRPC['eth'].eth_uninstallFilter(["#{id_filter}"])
end
