module Private
  class OrderAsksController < BaseController
    include Concerns::OrderCreation

    # before_action :gate_level1!, only: :create
    # before_action :gate_level2!, only: :create

    def create
      # binding.pry
      @order = OrderAsk.new(order_params(:order_ask))
      order_submit
    end

    def clear
      @orders = OrderAsk.where(member_id: current_user.id).with_state(:wait).with_currency(current_market)
      Ordering.new(@orders).cancel
      render status: 200, nothing: true
    end

  end
end
