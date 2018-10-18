module APIv2
  class Wallets < Grape::API
    helpers ::APIv2::NamedParams

    desc "User balances", hidden: true
    get "/getbalances" do
      jwt_token_authen!

      balances = []
      curr_member.accounts.each do |account|
        balances << {
          currency: account.currency,
          balance: account.balance,
          locked: account.locked,
          address: account.payment_addresses.last.present? ? account.payment_addresses.last.address : nil,
          image: "/funds_img/icon-"+account.currency+".png"
        }
      end
      json_success balances: balances
    end

    #---------------------------------------------#
    desc "Wallet withdraw", hidden: true
    params do
      requires :fund_source, type: String
      requires :currency, type: String
      requires :sum, type: Float
      optional :destination_tag, type: String
    end
    post "/withdraw" do
      jwt_token_authen!

      if curr_member.fund_sources.exists?(uid: params[:fund_source])
        fund_source = curr_member.fund_sources.find_by_uid(params[:fund_source])
      else
        fund_source = curr_member.fund_sources.new(
          :currency => params[:currency],
          :uid => params[:fund_source],
          :extra => params[:fund_source][0..3] + "..." + params[:fund_source][-4..-1]
          )

        fund_source.save
      end

      if params[:currency] == "btc" || params[:currency] == "bch" || params[:currency] == "btg"
        if params[:sum] < 0.005
          json_fails "limit_amount_withdraw"
        else
          currency = Currency.find_by_code(params[:currency])
          withdraw = "withdraws/#{currency.key.singularize}".camelize.constantize.new(
            :fund_source => fund_source.id,
            :member_id => curr_member.id,
            :currency => params[:currency],
            :sum => params[:sum]
          )
          if withdraw.save
            withdraw.submit!

            json_success
          else
            json_fails withdraw.errors.messages
          end
        end
      elsif params[:currency] == "eth" || params[:currency] == "etc"
        if params[:sum] < 0.1
          json_fails "limit_amount_withdraw"
        else
          currency = Currency.find_by_code(params[:currency])
          withdraw = "withdraws/#{currency.key.singularize}".camelize.constantize.new(
            :fund_source => fund_source.id,
            :member_id => curr_member.id,
            :currency => params[:currency],
            :sum => params[:sum]
          )
          if withdraw.save
            withdraw.submit!

            json_success
          else
            json_fails withdraw.errors.messages
          end
        end
      elsif params[:currency] == "kbr"
        account_user_eth = curr_member.accounts.find_by_currency(4)
        if @withdraw.sum.to_f < 1000
          json_fails "limit_amount_withdraw"
        elsif account_user_eth.balance < 0.005
          json_fails "insufficient_balance_ethereum"
        else
          if withdraw.save
            withdraw.submit!

            json_success
          else
            json_fails withdraw.errors.messages
          end
        end
      elsif params[:currency] == "jpyt"
        if curr_member.bank_account
          withdraw.assign_attributes :bank_account_id => current_user.bank_account.id
          if withdraw.save
            withdraw.submit!

            json_success
          else
            json_fails withdraw.errors.messages
          end
        else
          json_fails "missing_bank_account"
        end
      elsif params[:currency] == "xrp"
        balance = curr_member.accounts.find_by_currency(Currency.enumerize[:xrp]).balance
        sum = params[:sum].to_f

        destination_address = FundSource.where(id: params[:fund_source]).pluck(:uid).first
        account_flag = CoinRPC['xrp'].account_info([{
                      "account": destination_address,
                      "strict": true,
                      "ledger_index": "current",
                      "queue": true
                    }])

        if !account_flag["error"]
          if !account_flag["account_data"].nil? && account_flag["account_data"]["Flags"] != 0 && params[:destination_tag].nil?
            json_fails "missing_destination_tag"
          elsif !account_flag["account_data"].nil? && account_flag["account_data"]["Flags"] == 0 && !params[:destination_tag].nil?
            json_fails "dont_have_destination_tag"
          else
            if (balance - sum) > 20
              withdraw = "withdraws/#{currency.key.singularize}".camelize.constantize.new(
                :fund_source => fund_source.id,
                :member_id => member.id,
                :currency => params[:currency],
                :sum => params[:sum],
                :destination_tag => params[:destination_tag]
              )
              if withdraw.save
                withdraw.submit!
                json_success
              else
                json_fails withdraw.errors.messages
              end
            else
              json_fails "limit_amount_withdraw"
            end
          end
        else
          if !account_flag["validated"].nil?
            if sum < 20
              json_fails "limit_amount_active_account"
            else
              if (balance - sum) > 20
                withdraw = "withdraws/#{currency.key.singularize}".camelize.constantize.new(:fund_source => fund_source.id, :member_id => member.id, :currency => params[:currency], :sum => params[:sum])
                if withdraw.save
                  withdraw.submit!

                  json_success
                else
                  json_fails "withdraw.errors.messages"
                end
              else
                json_fails "limit_amount_withdraw"
              end
            end
          else
            json_fails "error_withdraw_address"
          end
        end
      else
        json_fails "error_invalid_currency"
      end
    end
    #---------------------------------------------#
    desc "Get deposits withdraw history", hidden: true
    params do
      requires :page, type: Integer
    end
    get "/assets_history" do
      jwt_token_authen!
      deposits = curr_member.deposits.with_aasm_state(:accepted)
      withdraws = curr_member.withdraws.with_aasm_state(:done)

      json_success(
        deposit_history: Kaminari.paginate_array(deposits).page(params[:page]).per(10),
        withdraw_history: Kaminari.paginate_array(withdraws).page(params[:page]).per(10),
      )
    end

    #---------------------------------------------#
    desc "Get list fund source", hidden: true
    params do
      optional :currency, type: String
    end
    get "/get_fund_sources" do
      jwt_token_authen!

      if params[:currency]
        json_success(
          fund_sources: curr_member.fund_sources.where(:currency => Currency.find_by_code(params[:currency]).id, :deleted_at => nil)
        )
      else
        json_success(
          fund_sources: curr_member.fund_sources.where(:deleted_at => nil)
        )
      end
    end

    #---------------------------------------------#
    desc "New fund source", hidden: true
    params do
      requires :label, type: String
      requires :address, type: String
      requires :currency, type: String, desc: "btc , eth or xrp ..."
    end

    post "/new_fund_source" do
      jwt_token_authen!

      new_fund_source = curr_member.fund_sources.new(
        :currency => params[:currency],
        :uid => params[:address],
        :extra => params[:label]
      )

      if new_fund_source.save
        json_success
      else
        json_fails "add new fund_sources fails"
      end
    end

    #---------------------------------------------#
    desc "Delete a fund source", hidden: true
    params do
      requires :id, type: String
    end

    post "/delete_fund_source" do
      jwt_token_authen!

      fund_source = curr_member.fund_sources.find_by_id(params[:id])

      if fund_source.destroy
        json_success
      else
        json_fails "destroy fund_sources fails"
      end
    end

    #---------------------------------------------#
    desc "Get fee", hidden: true
    params do
      requires :currency, type: String
    end

    get "/get_withdraw_fee" do
      currency = Currency.find_by_code(params[:currency])
      if currency
        json_success(
          fee: FeeTrade.find_by_currency(currency.id).amount
        )
      else
        json_fails "invalid_currency"
      end
    end

    #---------------------------------------------#
    desc 'Validate crypto currency address', hidden: true
    params do
      requires :address, type: String
      requires :currency, type: String
    end
    get "/validate_address" do
      case params[:currency]
      when "btc", "bch", "btg"
        begin
          result = CoinRPC["btc"].validateaddress(params[:address])
        rescue => e
          return json_fails e.backtrace.join("\n")
        end

        if result.nil? || (result[:isvalid] == false)
          json_fails "invalid_address"
        elsif PaymentAddress.find_by_address(params[:address])
          json_fails "address_in_hot_wallet"
        else
          json_success
        end
      when "xrp"
        begin
          result = CoinRPC['xrp'].account_info([{
              "account": params[:address],
              "strict": true,
              "ledger_index": "current",
              "queue": true
            }])
        rescue => e
          return json_fails e.backtrace.join("\n")
        end

        if result.nil? || result['validated'].nil?
          json_fails "invalid_address"
        elsif PaymentAddress.find_by_address(params[:currency])
          json_fails "address_in_hot_wallet"
        else
          json_success
        end
      when "eth", "etc" , "kbr"
        apikey = "ZUAMJJMM9H3NXRNA8PHE88S2QJ8KX98J4W"
        url = "https://api.etherscan.io/api?module=account&action=balance&address=#{params[:address]}&tag=latest&apikey=#{apikey}"
        response = HTTParty.get(url)
        return json_fails "currency invalid eth" if response.parsed_response["status"] != "1"

        json_success
      else
        json_fails "currency invalid"
      end
    end
  end
end
