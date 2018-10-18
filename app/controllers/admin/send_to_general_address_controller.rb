module Admin
  class SendToGeneralAddressController < BaseController
    def index
      @currencies_summary = Currency.all.map(&:summary)
      @currency = Array.new
      @currencies_summary.each do |c|
        if c[:coinable]
            @currency << c[:name]
        end
      end
    end

    def new
      if params[:currency] == "BTC"
        from = CoinRPC['btc'].validateaddress(params[:from_address])
        if from.nil? || (from[:isvalid] == false)
          redirect_to admin_send_to_general_address_index_path, alert: "Address is not valid"
          return
        end
        to = CoinRPC['btc'].validateaddress(params[:to_address])
        if to.nil? || (to[:isvalid] == false)
          redirect_to admin_send_to_general_address_index_path, alert: "Address is not valid"
          return
        end
        listunspent = CoinRPC['btc'].listunspent 0
        list = listunspent.select { |tx| tx["address"] == params[:from_address]}
        input = '['
        total_amount = 0
        list.each do |item|
          input = input + '{"txid": ' + "\"#{item["txid"].to_s}\"" + ', "vout": ' + "#{item["vout"].to_s}" + "}, "
          total_amount = total_amount + item["amount"].to_f
        end

        total_amount = (total_amount * 100000.to_f).floor / 100000.to_f
        send_amount = ((params[:amount].to_f - 0.0003) * 100000.to_f).floor / 100000.to_f
        input = input.gsub(/\, $/,"") + "]"
        a = JSON.parse(input)
        begin
          rawtx = CoinRPC['btc'].createrawtransaction a, { "#{params[:to_address]}": send_amount}
          signraw = CoinRPC['btc'].signrawtransaction(rawtx)
          txid = CoinRPC['btc'].sendrawtransaction(signraw[:hex])

          redirect_to admin_send_to_general_address_index_path, notice: txid
          return
        rescue
          redirect_to admin_send_to_general_address_index_path, alert: "Insufficient funds"
          return
        end 
      

      elsif params[:currency] == 'TAO'

        begin
          create = CoinRPC['tao'].create_send({"source": params[:from_address], "destination": params[:to_address], "asset": "TAOCOIN", "quantity": params[:amount].to_i, "fee": 24570})        
          signraw = CoinRPC['btc'].signrawtransaction(create)
          txid = CoinRPC['btc'].sendrawtransaction(signraw[:hex])
        rescue
          redirect_to admin_send_to_general_address_index_path, alert: "Insufficient funds"
          return
        end
      end
    end

    private
    def send_coin_params
      params.require(:send_to_general_address).permit(:currency, :from_address, :to_address, :amount)
    end
  end
end