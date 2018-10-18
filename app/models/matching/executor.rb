require_relative 'constants'

module Matching
  class Executor

    def initialize(payload)
      @payload = payload
      @market  = Market.find payload[:market_id]
      @price   = BigDecimal.new payload[:strike_price]
      @volume  = BigDecimal.new payload[:volume]
      @funds   = BigDecimal.new payload[:funds]
    end

    def execute!
      retry_on_error(5) { create_trade_and_strike_orders }
      publish_trade
      @trade
    end

    private

    def valid?
      return false if @ask.ord_type == 'limit' && @ask.price > @price
      return false if @bid.ord_type == 'limit' && @bid.price < @price
      @funds > ZERO && [@ask.volume, @bid.volume].min >= @volume
    end

    def trend
      @price >= @market.latest_price ? 'up' : 'down'
    end

    # in worst condition, the method will run 1+retry_count times then fail
    def retry_on_error(retry_count, &block)
      block.call
    rescue ActiveRecord::StatementInvalid
      # cope with "Mysql2::Error: Deadlock found ..." exception
      if retry_count > 0
        sleep 0.2
        retry_count -= 1
        puts "Retry trade execution (#{retry_count} retry left) .."
        retry
      else
        puts "Failed to execute trade: #{@payload.inspect}"
        raise $!
      end
    end

    def create_trade_and_strike_orders
      ActiveRecord::Base.transaction do
        @ask = OrderAsk.lock(true).find(@payload[:ask_id])
        @bid = OrderBid.lock(true).find(@payload[:bid_id])

        raise TradeExecutionError.new({ask: @ask, bid: @bid, price: @price, volume: @volume, funds: @funds}) unless valid?

        @trade = Trade.create!(ask_id: @ask.id, ask_member_id: @ask.member_id,
                               bid_id: @bid.id, bid_member_id: @bid.member_id,
                               price: @price, volume: @volume, funds: @funds,
                               currency: @market.id.to_sym, trend: trend)

        @bid.strike @trade
        @ask.strike @trade
      end

      ##bonus affiliate if user trade btc > 0.1
      if Member.count > 10000
        if @trade.ask_member_id == @trade.bid_member_id
          array = [@trade.ask_member_id]
        else
          array = [@trade.ask_member_id, @trade.bid_member_id]
        end
        Rails.logger.info "array: #{array}"
        check_bonus_affiliate(array: array)
      end

      # TODO: temporary fix, can be removed after pusher -> polling refactoring
      if @trade.ask_member_id == @trade.bid_member_id
        @ask.hold_account.reload.trigger
        @bid.hold_account.reload.trigger
      end
    end

    def check_bonus_affiliate(array: nil)
      array.each do |a|
        member = Member.find_by_id(a)
        if member.affiliate_member_id && !member.check_bonus_trade
          update_bonus_affiliate(member)
        end
      end
    end

    def update_bonus_affiliate(member)
      parent_affiliate = Member.find_by_id(member.affiliate_member_id)
      affiliate = Affiliate.find_by_member_id(member.affiliate_member_id)
      bonus_money_trade = 2000
      if parent_affiliate
        btc_trade = sum_btc_trade(member)
        if btc_trade > 0.1
          parent_affiliate.accounts.find_by(:currency => 1).lock!.plus_funds bonus_money_trade, reason: Account::BONUS_AFFILIATE, ref: nil
          member.update_attributes(check_bonus_trade: true)
          if affiliate.bonus.nil?
            affiliate.bonus = 2000
          else
            affiliate.bonus = 2000 + affiliate.bonus
          end
          affiliate.save!
        end
      end
    end

    def sum_btc_trade(user)
      btc_exchange_ask = Market.all.select {|x| x.base_unit == 'btc'}
      btc_exchange_code_ask = btc_exchange_ask.map(&:code)
      btc_ask = user.trades.select {|x| x["currency"].in? btc_exchange_code_ask}
      btc_ask_sum = btc_ask.sum(&:volume).to_f

      btc_exchange_bid = Market.all.select {|x| x.quote_unit == 'btc'}
      btc_exchange_code_bid = btc_exchange_bid.map(&:code)
      btc_bid = user.trades.select {|x| x["currency"].in? btc_exchange_code_bid}
      btc_bid_sum = btc_bid.sum(&:price).to_f

      return btc_ask_sum + btc_bid_sum
    end

    def publish_trade
      AMQPQueue.publish(
        :trade,
        @trade.as_json,
        { headers: {
            market: @market.id,
            ask_member_id: @ask.member_id,
            bid_member_id: @bid.member_id
          }
        }
      )
    end

  end
end
