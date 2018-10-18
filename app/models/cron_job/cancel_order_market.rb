module CronJob
  class CancelOrderMarket
    def self.handle
      orders = Order.where(state: 100)      
      orders.each do |o|
        if ((Time.now - o.updated_at)/86400) >= 15
          Ordering.new(o).cancel
        end
      end
    end
  end
end
