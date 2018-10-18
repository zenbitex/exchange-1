module APIv2
  class CloudsafeServices < Grape::API

    # trade by jpy, btc
    desc "Create a trade", hidden: true
    params do
      requires :email, type: String
      requires :amount, type: Float
      requires :price, type: Float
      requires :currency, type: String
      optional :exchange_rate, type: Float
    end
    post "/cloudsafe_trades" do
      member = Member.find_by_email(params[:email])
      if member
        account = member.accounts.find_by_currency(3)
        if params[:currency] == 'jpy'
          if params[:exchange_rate] != 0
            exchange_rate_jpy = ExchangeRates.find_by_currency("jpy").rate.to_f
            price_jpy = (params[:amount].to_f * exchange_rate_jpy).ceil

            if params[:price].to_f == price_jpy
              trade = TaocoinTrades.new({
                account_id: account.id,
                amount: params[:amount],
                price: params[:price],
                exchangerate: params[:exchange_rate],
                status_id: 0,
                currency: params[:currency]
                })
                trade.save
              end
            else
              trade = TaocoinTrades.new({
                account_id: account.id,
                amount: params[:amount],
                price: params[:price],
                status_id: 0,
                currency: params[:currency],
                })
                trade.save
              end
              if trade.nil? || trade.errors.any?
                {
                  "error" => true
                }
              else
                TradeMailer.trade_email(trade.id).deliver
                present trade, with: APIv2::Entities::TaocoinTrade
              end
            elsif params[:currency] == 'btc'
              taocoin_fund_source = TaocoinFundSources.find_by_account_id(account.id)
              unless taocoin_fund_source
                taocoin_fund_source = TaocoinFundSources.new ({
                  account_id: account.id,
                  btc_address: CoinRPC['btc'].getnewaddress('payment')
                  })
                  taocoin_fund_source.save
                end
                if params[:exchange_rate] != 0
                  exchange_rate_btc = ExchangeRates.find_by_currency("btc").rate.to_f

                  price_btc = ((params[:amount].to_f * exchange_rate_btc * 100000.to_f).ceil / 100000.to_f)
                  if params[:price].to_f == price_btc
                    trade = TaocoinTrades.new({
                      account_id: account.id,
                      amount: params[:amount],
                      price: params[:price],
                      exchangerate: params[:exchange_rate],
                      status_id: 0,
                      currency: params[:currency],
                      taocoin_fund_source_id: taocoin_fund_source.id
                      })
                      trade.save
                    end
                  else
                    trade = TaocoinTrades.new({
                      account_id: account.id,
                      amount: params[:amount],
                      price: params[:price],
                      status_id: 0,
                      currency: params[:currency],
                      taocoin_fund_source_id: taocoin_fund_source.id
                      })
                      trade.save
                    end
                    if trade.nil? || trade.errors.any?
                      {
                        "error" => true
                      }
                    else
                      TradeMailer.btc_trade_email(trade.id).deliver
                      present trade, with: APIv2::Entities::TaocoinTradeBTC
                    end
                  end

                else
                  {
                    "error" => true,
                    "messages" => "Account is not valid"
                  }
                end

              end

              # trade by paypal
              desc "Submit a paypal trade", hidden: true
              params do
                requires :email, type: String
                requires :item_number, type: Float
                requires :payment_gross, type: Float
                requires :mc_currency, type: String
                optional :exchange_rate, type: Float
                optional :payment_status, type: String
                optional :txn_id, type: String
              end
              post "/cloudsafe_paypal_trades" do
                member = Member.find_by_email(params[:email])
                if params[:txn_id].nil? || TaocoinTrades.where(token: params[:txn_id]).first
                  redirect "https://taocoin.asia/paypal-details"
                else
                  if member
                    account = member.accounts.find_by_currency(3)
                    if params[:mc_currency] == "USD"
                      if params[:exchange_rate]

                        exchange_rate_usd = ExchangeRates.find_by_currency("usd").rate.to_f
                        price_usd = ((params[:item_number].to_f * exchange_rate_usd * 100.to_f).ceil / 100.to_f)

                        if params[:payment_gross].to_f == price_usd
                          trade = TaocoinTrades.where(:account_id => account.id).last
                          trade.update_attributes(
                          account_id: account.id,
                          amount: params[:item_number],
                          price: params[:payment_gross],
                          exchangerate: params[:exchange_rate],
                          currency: 'usd',
                          token: params[:txn_id]
                          )
                        end

                      else
                        trade = TaocoinTrades.where(:account_id => account.id).last
                        trade.update_attributes(
                        account_id: account.id,
                        amount: params[:item_number],
                        price: params[:payment_gross],
                        currency: 'usd',
                        token: params[:txn_id]
                        )

                      end
                      selectadmin = Account.find_by(:member_id => 1,:currency => 3)
                      admin_balance = selectadmin.balance.to_i
                      user_account = member.accounts.find_by(:currency => 3)
                      if trade
                        if params[:payment_status] == "Completed" && admin_balance > trade.amount
                          selectadmin.lock!.sub_funds trade.amount, reason: Account::CLOUD_SAFE_SELL, ref: nil
                          user_account.lock!.plus_funds trade.amount, reason: Account::CLOUD_SAFE_BUY, ref: nil

                          trade.update_attributes(notification_params: params, :status_id => 1, purchased_at: Time.now)
                          TradeMailer.paypal_email(trade.id).deliver
                          redirect "https://taocoin.asia/paypal/#{trade.tradecode}"
                        else
                          trade.update_attributes(notification_params: params, :status_id => 2)
                          TradeMailer.paypal_email(trade.id).deliver
                          redirect "https://taocoin.asia/paypal/#{trade.tradecode}"
                        end
                      else
                        {
                          "error" => true
                        }
                      end
                    end
                  else
                    {
                      "error" => true,
                      "messages" => "Account is not valid"
                    }
                  end
                end
              end

              desc "Create a paypal trade", hidden: true
              params do
                requires :email, type: String
                requires :amount, type: Float
                requires :price, type: Float
                requires :currency, type: String
                optional :exchange_rate, type: Float
              end
              post "/create_paypal_trade" do
                member = Member.find_by_email(params[:email])
                if member
                  account = member.accounts.find_by_currency(3)
                  if params[:currency] == 'usd'
                    if params[:exchange_rate] != 0
                      exchange_rate_usd = ExchangeRates.find_by_currency("usd").rate.to_f
                      price_usd = ((params[:amount].to_f * exchange_rate_usd * 100.to_f).ceil / 100.to_f)

                      if params[:price].to_f == price_usd
                        trade = TaocoinTrades.new({
                          account_id: account.id,
                          amount: params[:amount],
                          price: params[:price],
                          exchangerate: params[:exchange_rate],
                          status_id: 0,
                          currency: params[:currency]
                          })
                          trade.save
                        end
                      else
                        trade = TaocoinTrades.new({
                          account_id: account.id,
                          amount: params[:amount],
                          price: params[:price],
                          status_id: 0,
                          currency: params[:currency],
                          })
                          trade.save
                        end
                        if trade.nil? || trade.errors.any?
                          {
                            "error" => true
                          }
                        else
                          {
                            "success" => true
                          }
                        end
                      else
                        {
                          "error" => true,
                          "message" => "wrong currency"
                        }
                      end
                    else
                      {
                        "error" => true,
                        "messages" => "Account is not valid"
                      }
                    end
                  end

                  # get currency
                  desc 'Get all currencies.', hidden: true
                  get "/currencies" do
                    present Currencies.all, with: APIv2::Entities::TypeTrade
                  end

                  # get exchange rate
                  desc 'Get all exchange rate.', hidden: true
                  get "/rates" do
                    rates = ExchangeRates.all
                    present rates, with: APIv2::Entities::Rate
                  end

                  # get option
                  desc 'Get all options.', hidden: true
                  params do
                    requires :currency, type: String
                  end
                  get "/options" do
                    options = BuyOptions.where currency: params[:currency]
                    present options, with: APIv2::Entities::BuyOption
                  end

                  # get paypal trade
                  desc "Return paypal", hidden: true
                  params do
                    requires :tradecode, type: String
                  end
                  get "/get_paypal_trade" do
                    trade = TaocoinTrades.find_by_tradecode(params[:tradecode])
                    present trade, with: APIv2::Entities::TaocoinTrade
                  end

                  # total taocoin
                  desc "Total TAOCOIN", hidden: true
                  get "/total_taocoin" do
                    selectadmin = Account.find_by(:member_id => 1,:currency => 3)
                    admin_balance = selectadmin.balance
                    {
                      'total' => admin_balance.to_i
                    }
                  end

                  # history cloudsafe
                  desc "History cloudsafe", hidden: true
                  params do
                    requires :email, type: String
                  end
                  post "/cloudsafe_history" do
                    member = Member.find_by_email(params[:email])
                    if member
                      account = member.accounts.find_by_currency(3)
                      history = TaocoinTrades.where(:account_id => account)
                      present history, with: APIv2::Entities::History
                    else
                      {
                        "error" => true,
                        "messages" => "Email is not valid"
                      }
                    end
                  end

                  # user accounts
                  desc "User account", hidden: true
                  params do
                    requires :email, type: String
                  end
                  post "/user_account" do
                    member = Member.find_by_email(params[:email])
                    if member
                      {
                        "btc" => member.accounts.find_by_currency(2).balance.to_f,
                        "tao" => member.accounts.find_by_currency(3).balance.to_f
                      }
                    else
                      {
                        "error" => true,
                        "messages" => "Email is not valid"
                      }
                    end
                  end

                  # count fee cold wallet
                  desc "Count fee cold wallet", hidden: true
                  params do
                    requires :currency, type: String
                    requires :address, type: String
                    requires :amount, type: Float
                    optional :fee, type: Float
                  end
                  post "/count_fee" do
                    begin
                      currency = params[:currency]
                      if currency == "btc"
                        if params[:fee] > 0.0001
                          fee = params[:fee].to_f
                        else
                          fee = 0.0001
                        end
                        holding_btc = Currency.find_by_code('btc').address
                        listunspent = CoinRPC['btc'].listunspent 0
                        list = listunspent.select { |tx| tx["address"] == holding_btc }.sort_by { |tx| -tx["amount"] }
                        input = '['
                        total_amount = 0
                        list.each do |item|
                          input = input + '{"txid": ' + "\"#{item["txid"].to_s}\"" + ', "vout": ' + "#{item["vout"].to_s}" + "}, "
                          total_amount = total_amount + item["amount"].to_f
                          break if total_amount > (params[:amount].to_f + fee)
                        end
                        total_amount = (total_amount * 100000.to_f).floor / 100000.to_f
                        send_amount = params[:amount].to_f
                        receive_amount = ((total_amount - params[:amount].to_f - fee) * 100000.to_f).floor / 100000.to_f
                        input = input.gsub(/\, $/,"") + "]"
                        a = JSON.parse(input)
                        rawtx = CoinRPC['btc'].createrawtransaction a, { "#{params[:address]}": send_amount, "#{holding_btc}": receive_amount}
                        signraw = CoinRPC['btc'].signrawtransaction(rawtx)
                        decoderawtx = CoinRPC['btc'].decoderawtransaction(signraw[:hex])
                        {
                          "fee" => decoderawtx[:size] * 130 * 0.00000001
                        }
                      elsif currency == "bch"
                        if params[:fee] > 0.0001
                          fee = params[:fee].to_f
                        else
                          fee = 0.0001
                        end
                        receive_address = PaymentAddress.find_by_currency(10).address
                        listunspent = CoinRPC[currency].listunspent 0
                        list = listunspent.sort_by{ |tx| -tx["amount"] }
                        input = '['
                        total_amount = 0
                        list.each do |item|
                          input = input + '{"txid": ' + "\"#{item["txid"].to_s}\"" + ', "vout": ' + "#{item["vout"].to_s}" + "}, "
                          total_amount = total_amount + item["amount"].to_f
                          break if total_amount > (params[:amount].to_f + fee)
                        end
                        total_amount = (total_amount * 100000.to_f).floor / 100000.to_f
                        send_amount = params[:amount].to_f
                        receive_amount = ((total_amount - params[:amount].to_f - fee) * 100000.to_f).floor / 100000.to_f
                        input = input.gsub(/\, $/,"") + "]"
                        a = JSON.parse(input)
                        rawtx = CoinRPC[currency].createrawtransaction a, { "#{params[:address]}": send_amount, "#{receive_address}": receive_amount}
                        signraw = CoinRPC[currency].signrawtransaction(rawtx)
                        decoderawtx = CoinRPC[currency].decoderawtransaction(signraw[:hex])
                        {
                          "fee" => decoderawtx[:size] * 130 * 0.00000001
                        }
                      end
                    rescue
                      throw :error, :message => 'Invalid address or amount', :status => 500
                    end
                  end
                end
              end
