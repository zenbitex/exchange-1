class Ordering

  class CancelOrderError < StandardError; end

  def initialize(order_or_orders)
    @orders = Array(order_or_orders)
  end

  def submit market = nil
    ActiveRecord::Base.transaction do
      @orders.each {|order| do_submit order }
    end

    @orders.each do |order|
      AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
    end
    update_book market
    true
  end

  def cancel
    @orders.each {|order| do_cancel order }
  end

  def cancel!
    ActiveRecord::Base.transaction do
      @orders.each {|order| do_cancel! order }
    end
  end

  def update_book market
    return if market.nil? || @orders[0].nil?
    depth = Hash.new {|h, k| h[k] = 0 }
    type_order = @orders[0].type
    code_market = Market.find(market).code

    if type_order == "OrderBid"
      orders = Order.active.where(type: type_order, currency: code_market).order('price DESC')
    else
      orders = Order.active.where(type: type_order, currency: code_market).order('price ASC')
    end

    orders.each do |order|
      price = order.price
      depth[price] += order.volume
    end

    depth = depth.to_a
    if type_order == "OrderBid"
      asks = Rails.cache.read("exchangepro:#{market}:depth:asks") || []
      bids = depth
    else
      asks = depth
      bids = Rails.cache.read("exchangepro:#{market}:depth:bids") || []
    end

    # binding.pry

    while(true)
      asks, bids, is_finis = merge_trade asks, bids
      if is_finis
        break
      end
    end

    Rails.cache.write "exchangepro:#{market}:depth:asks", asks
    Rails.cache.write "exchangepro:#{market}:depth:bids", bids

    Pusher.trigger_async("market-#{market}-global", 'update', asks: asks, bids: bids, reason: "order new")
  end

  def merge_trade asks, bids
    if asks[0] && bids[0] && asks[0][0] <= bids[0][0]
      amount = [asks[0][1], bids[0][1]].max
      ask = amount - asks[0][1]
      bid = amount - bids[0][1]
      is_finis = false
      if bid == 0
        bids[0][1] = ask
        if ask == 0
          bids.delete_at 0
          is_finis = true
        end
        asks.delete_at 0
      else
        asks[0][1] = bid
        if bid == 0
          asks.delete_at 0
          is_finis = true
        end
        bids.delete_at 0
      end
      return asks, bids, is_finis
    else
      return asks, bids, true
    end
  end

  private

  def do_submit(order)
    order.fix_number_precision # number must be fixed before computing locked
    order.locked = order.origin_locked = order.compute_locked
    order.save!

    account = order.hold_account
    account.lock_funds(order.locked, reason: Account::ORDER_SUBMIT, ref: order)
  end

  def do_cancel(order)
    AMQPQueue.enqueue(:matching, action: 'cancel', order: order.to_matching_attributes)
  end

  def do_cancel!(order)
    account = order.hold_account
    order   = Order.find(order.id).lock!

    if order.state == Order::WAIT
      order.state = Order::CANCEL
      account.unlock_funds(order.locked, reason: Account::ORDER_CANCEL, ref: order)
      order.save!
    else
      raise CancelOrderError, "Only active order can be cancelled. id: #{order.id}, state: #{order.state}"
    end
  end

end
