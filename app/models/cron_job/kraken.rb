module CronJob
  class KrakenJob
    class <<self
      INTERVAL = 30
      def update_price_btcjpy
        update_price "btcjpy"
      end

      def update_price_xrpjpy
        update_price "xrpjpy"
      end

      def update_price_xrpbtc
        update_price "xrpbtc"
      end

      def update_price market
        fee = CoinTradePrice.find_by_market(market,"TradeBid").fee
        while 1
          start_time = Time.now
          kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
          chanel = 'kraken-price'
          data = kraken.buy_sell_best(market, fee)
          Rails.cache.write chanel + "-#{market}", data
          Pusher.trigger_async(chanel, market, data)
          end_time = Time.now
          diff = INTERVAL - (end_time - start_time).to_f
          diff = diff > 0 ? diff : 0
          sleep(diff)
        end
      end

      def check_order_state
        kraken = Kraken::Client.new(ENV['KRAKEN_PUBLIC_KEY'], ENV['KRAKEN_SECRET_KEY'])
        # check_submit_order(CoinTrade.where('aasm_state=?', :submit))
        check_watting_order(kraken, CoinTrade.where('aasm_state=?', :waiting))
        check_withdrawing_order(kraken, CoinTrade.where('aasm_state=?', :withdrawing))
      end

      # def check_submit_order(order_submit)
      #   order_submit.each do |o|
      #     o.order_to_kraken
      #   end
      # end

      def check_watting_order(kraken, order_waiting)
        order_waiting.each do |o|
          state = kraken.check_order_status(o.txid)
          next unless state
          o.order_done! if state == 'closed'
        end
      end

      def check_withdrawing_order(kraken, order_transacted)
        order_transacted.each do |t|
          state = kraken.withdraw_status(t.currency, t.withdraw_txid)
          t.finish! if state == 'Success'
        end
      end
    end
  end
end
