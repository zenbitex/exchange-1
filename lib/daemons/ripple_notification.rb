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

@ws_cli = nil
$rippleaddress = PaymentAddress.where(currency: 5).where.not(address: nil).pluck(:address)
logger.debug $rippleaddress
def subscribe
    subscribe_cmd = {
	  :id => "Example watch for new validated ledgers",
	  :command => "subscribe",
	  :accounts => $rippleaddress
	  # :streams => ["transactions"]
	}

	subscribe_str = subscribe_cmd.to_json.to_s.gsub!(/\"/, "\"")
    @ws_cli.send (subscribe_str)
end

WebSocket::Client::Simple.connect ENV['RIPPLE_SERVER'] do |ws|
  @ws_cli = ws
  ws.on :open do
    logger.debug "connect!"
    # subscribe
  end

  ws.on :message do |msg|
    # logger.debug "here come msg"
    # logger.debug msg
    transaction = JSON.parse msg.to_s
    # logger.debug "transaction"
    logger.debug transaction
    # logger.debug transaction["transaction"]["Destination"]
    if !transaction['engine_result'].nil?
      # logger.debug "khac nil"
      # logger.debug "test success #{transaction['engine_result'] == 'tesSUCCESS'}"
      logger.debug transaction["transaction"]["Destination"]
      # logger.debug "database address #{$rippleaddress}"
      # logger.debug transaction["transaction"]["Destination"].in?($rippleaddress)
      user_rippleaddress = PaymentAddress.where(currency: 5).where.not(address: nil).pluck(:address)
      logger.debug user_rippleaddress
      if transaction["transaction"]["Destination"].in?(user_rippleaddress)
        logger.debug "OKsfdfdsf"
        tx = transaction["transaction"]["hash"]
        payload = {txid: tx}
        attrs = {persistent: true}
        AMQPQueue.enqueue(:deposit_ripple, payload, attrs)
      end
    end
    
  end
end

while($running) do
  $rippleaddress = PaymentAddress.where(currency: 5).where.not(address: nil).pluck(:address)
  subscribe
  # logger.debug "Refresh database"
  # logger.debug $rippleaddress
  
  sleep 1
end
