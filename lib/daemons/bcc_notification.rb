#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require "bunny"
require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do
  $running = false
end
Rails.logger = logger = Logger.new STDOUT

conn = Bunny.new("amqp://bch_admin:password_admin@13.231.17.237:5672")
conn.start

ch   = conn.create_channel
q    = ch.queue("bch-notification", durable: true)

while($running) do
  begin
    # puts " [*] Waiting for messages. To exit press CTRL+C"
    q.subscribe(:block => true) do |delivery_info, properties, body|
      # puts " [x] Received #{body}"
      payload = JSON.parse(body)
      attrs = {persistent: true}
      AMQPQueue.enqueue(:deposit_coin, payload, attrs)
    end
  rescue Interrupt => _
    conn.close

    exit(0)
  end
  
  sleep 5
end