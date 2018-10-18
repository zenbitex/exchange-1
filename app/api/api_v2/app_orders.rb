module APIv2
  class AppOrders < Grape::API
  helpers ::APIv2::NamedParams

    desc 'Create a Sell/Buy order from App.', scopes: %w(trade)
    params do
      requires :market, type: String
      requires :price, type: String
      requires :volume, type: String
      optional :side, type: String
    end

    post "/app_orders" do
      jwt_token_authen!

      order = create_order_app params, curr_member.id
      # present order, with: APIv2::Entities::Order
      json_success(
        order: order
      )
    end
  end
end
