json.asks @asks
json.bids @bids
json.trades @trades
json.api_url @api_url

if @member
  json.my_trades @trades_done.map(&:for_notify)
  json.my_orders *([@orders_wait] + Order::ATTRIBUTES)
end
