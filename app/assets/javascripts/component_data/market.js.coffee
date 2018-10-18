@MarketData = flight.component ->

  $.marketApp = angular.module('market', []);

  $.accountController = $.marketApp.controller 'AccountController', ['$scope', ($scope) ->
    $scope.accounts = gon.accounts
  ]

  $.orderController = $.marketApp.controller 'OrderController', ['$scope', ($scope) =>
    #in btcjpy,  bid is jpy, ask is btc
    $scope.markets = angular.element($('#table_orders')).data('market').split('/');
    $scope.maxRow = 20
    $scope.balance_bid = 0
    $scope.balance_ask = 0
    $scope.precision_bid = gon.market.bid.fixed
    $scope.precision_ask = gon.market.ask.fixed
    $scope.market_id = gon.market.id
    $scope.sellingFee = 0
    $scope.buyingFee = 0
    $scope.fee_fixed = gon.market.fee_fixed

    # calculate rates
    current_market = gon.markets[$scope.markets[0].toLowerCase() + $scope.markets[1].toLowerCase()]
    $scope.buyingFeeRate = current_market.bid.fee
    $scope.sellingFeeRate = current_market.ask.fee
    $scope.sell_fee = current_market.ask.fee
    $scope.buy_fee = current_market.bid.fee

    $scope.resetForm = ()->
      $scope.sellingPrice = ""
      $scope.sellingAmount = ""
      $scope.sellingTotal = ""
      $scope.sellingFee = ""
      $scope.buyingPrice = ""
      $scope.buyingAmount = ""
      $scope.buyingTotal = ""
      $scope.buyingFee = ""

    $scope.switchForm = (type) ->
      sell_form = $('#ask_entry')
      buy_form = $('#bid_entry')
      $(".switch-order-type .btn").removeClass "active"
      switch type
        when "buy"
          buy_form.show()
          sell_form.hide()
          $(".switch-order-type .btn-primary").addClass "active"
        when "sell"
          $(".switch-order-type .btn-danger").addClass "active"
          sell_form.show()
          buy_form.hide()
      return true

    $scope.closeConfirm = ->
      $(".confirm_order").attr("style", "display: none")
      return false

    $scope.confirmOrder = ->
      $(".btn-order").text($(event.target).text());
      $(".confirm_order").attr("style", "display: flex")
      $(".confirm_order").attr("data", $(event.target).parents("form").attr("id"))
      event.preventDefault()

    $scope.submitOrder = ->
      $("#" + $(".confirm_order").attr("data")).submit()
      $scope.closeConfirm()

    #Sell form
    $scope.$watch 'sellingAmount', (new_val, old_val) ->
      if new_val
        $scope.sellingAmount = Number(new_val.toFixed($scope.precision_ask))
      if $scope.sellingPrice && new_val
        $scope.sellingTotal = ($scope.sellingAmount * $scope.sellingPrice).toFixed($scope.precision_bid)
        $scope.sellingFee = ($scope.sell_fee * $scope.sellingTotal).toFixed($scope.fee_fixed)
    $scope.$watch 'sellingPrice', (new_val, old_val) ->
      if new_val
        $scope.sellingPrice = Number(new_val.toFixed($scope.precision_bid))
      if $scope.sellingAmount && new_val
        $scope.sellingTotal = ($scope.sellingAmount * $scope.sellingPrice).toFixed($scope.precision_bid)
        $scope.sellingFee = ($scope.sell_fee * $scope.sellingTotal).toFixed($scope.fee_fixed)

    #Buying Form
    $scope.$watch 'buyingAmount', (new_val, old_val) ->
      if new_val
        $scope.buyingAmount = Number(new_val.toFixed($scope.precision_ask))
      if $scope.buyingPrice && new_val
        $scope.buyingTotal = ($scope.buyingAmount * $scope.buyingPrice).toFixed($scope.precision_bid)
        $scope.buyingFee = ($scope.buy_fee * $scope.buyingTotal).toFixed($scope.fee_fixed)
    $scope.$watch 'buyingPrice', (new_val, old_val) ->
      if new_val
        $scope.buyingPrice = Number(new_val.toFixed($scope.precision_bid))
      if $scope.buyingAmount && new_val
        $scope.buyingTotal = ($scope.buyingAmount * $scope.buyingPrice).toFixed($scope.precision_bid)
        $scope.buyingFee = ($scope.buy_fee * $scope.buyingTotal).toFixed($scope.fee_fixed)

    $scope.isValidVolume = (price, fixed) ->
      if (fixed == 0)
        Number.isInteger(Number(price))
      else
        values = price.split('.')
        (values.length == 1) || (values[1].length <= fixed)

    $scope.setBuySellPrice = (item)->
        $scope.sellingPrice = Number(item.price)
        $scope.buyingPrice = Number(item.price)
        # $scope.validatePrice()

    $scope.validatePrice = ->
      price = $scope.sellingPrice
      validData = !isNaN(price) && $scope.isValidVolume(price, gon.market.bid.fixed)
      # check with current balance
      if validData
        price = 0
        amount = 0
        price =  Number($scope.sellingPrice)
        amount = Number($scope.sellingAmount)
        total = price * amount
        $scope.lastSellingPrice = $scope.sellingPrice
        $scope.sellingTotal = String(total.toFixed(current_market.bid.fixed))
        $scope.sellingFee = String((total*$scope.fee).toFixed(current_market.bid.fixed))
      else
        # revert back to previous valid value
        $scope.sellingPrice = $scope.lastSellingPrice

    $scope.resetForm()
  ]

  @resetForm = ()->
    scope = angular.element($('#place_order')).scope();
    scope.$apply ()->
      scope.resetForm()

  @refreshBalance = (event, data) ->
    currency_bid = gon.market['bid'].currency
    balance_bid = gon.accounts[currency_bid]?.balance || 0
    currency_ask = gon.market['ask'].currency
    balance_ask = gon.accounts[currency_ask]?.balance || 0
    scope = angular.element($('#place_order')).scope()
    scope.$apply ()->
      scope.balance_bid = balance_bid
      scope.balance_ask = balance_ask

  @load = () ->
    @tradesCache = []
    @trigger 'market::charts::request_data'
    @reqK gon.market.id, 1

  @reqK = (market, minutes, limit = 6000) ->
    @refreshUpdatedAt()
    tid = if gon.trades.length > 0 then gon.trades[0].tid else 0
    tid = @last_tid+1 if @last_tid
    url = "/api/v2/k_with_pending_trades.json?market=#{market}&limit=#{limit}&period=#{minutes}&trade_id=#{tid}"
    $.getJSON url, (data) =>
      @handleData(data, minutes)
      @startDeliver()

  @checkTrend = (pre, cur) ->
    # time, open, high, low, close, volume
    [_, _, _, _, cur_close, _] = cur
    [_, _, _, _, pre_close, _] = pre
    cur_close >= pre_close # {true: up, false: down}

  @createPoint = (i, trade) ->
    # if the gap between old and new point is too wide (> 100 points), stop live
    # load and show hints
    gap = Math.floor((trade.date-@next_ts) / (@minutes*60))
    if gap > 100
      console.log "failed to update, too wide gap."
      window.clearInterval @interval
      return i

    while trade.date >= @next_ts
      x = @next_ts*1000

      @last_ts = @next_ts
      @next_ts = @last_ts + @minutes*60

      [p, v]= if (trade.date < @next_ts)
                [parseFloat(trade.price), parseFloat(trade.amount)]
              else
                [@points.close[i][1], 0]

      @points.close.push [x, p]
      @points.candlestick.push [x, p, p, p, p]
      @points.volume.push {x: x, y: v, color: if p >= @points.close[i][1] then 'rgba(0, 255, 0, 0.5)' else 'rgba(255, 0, 0, 0.5)'}
      i += 1
    i

  @updatePoint = (i, trade) ->
    p = parseFloat(trade.price)
    v = parseFloat(trade.amount)

    @points.close[i][1] = p

    if p > @points.candlestick[i][2]
      @points.candlestick[i][2] = p
    else if p < @points.candlestick[i][3]
      @points.candlestick[i][3] = p
    @points.candlestick[i][4] = p

    @points.volume[i].y += v
    @points.volume[i].color = if i > 0 && @points.close[i][1] >= @points.close[i-1][1] then 'rgba(0, 255, 0, 0.5)' else 'rgba(255, 0, 0, 0.5)'

  @refreshUpdatedAt = ->
    @updated_at = Math.round(new Date().valueOf()/1000)

  @prepare = (k) ->
    [volume, candlestick, close_price] = [[], [], []]

    for cur, i in k
      # console.log cur, i
      [time, open, high, low, close, vol] = cur
      time = time * 1000 # fixed unix timestamp for highsotck
      trend = if i >= 1 then @checkTrend(k[i-1], cur) else true

      close_price.push [time, close]
      candlestick.push [time, open, high, low, close]
      volume.push {x: time, y: vol, color: if trend then 'rgba(0, 255, 0, 0.5)' else 'rgba(255, 0, 0, 0.5)'}

    # remove last point from result, because we'll re-calculate it later
    minutes: @minutes, candlestick: candlestick.slice(0, -1), volume: volume.slice(0, -1), close: close_price.slice(0, -1)

  @handleData = (data, minutes) ->
    @minutes = minutes
    @tradesCache =  @tradesCache.concat data.trades

    @points   = @prepare data.k
    @last_tid = 0
    if @points.candlestick.length > 0
      @last_ts = @points.candlestick[@points.candlestick.length-1][0]/1000
    else
      @last_ts = 0
    @next_ts = @last_ts + minutes*60 # seconds

    @deliverTrades 'data'

  @processTrades = ->
    i = @points.candlestick.length - 1
    $.each @tradesCache, (ti, trade) =>
      if trade.tid > @last_tid
        if @last_ts <= trade.date && trade.date < @next_ts
          @updatePoint i, trade
        else if @next_ts <= trade.date
          i = @createPoint i, trade
        @last_tid = trade.tid
        @refreshUpdatedAt()
    @tradesCache = []

  @deliverTrades = (event_type) ->
    @processTrades()
    # skip the first point
    @trigger 'market::linechart::'+event_type,
      minutes: @points.minutes
      close: @points.close.slice(1)

    @trigger  'market::candlestick::' + event_type,
      minutes: @points.minutes
      candlestick: @points.candlestick.slice(1)
      close: @points.close.slice(1)
      volume: @points.volume.slice(1)

    # we only need to keep the last 2 points for future calculation
    @points.close = @points.close.slice(-2)
    @points.candlestick = @points.candlestick.slice(-2)
    @points.volume = @points.volume.slice(-2)

  @hardRefresh = (threshold_in_sec) ->
    ts = Math.round(new Date().valueOf()/1000)
    # if there's no trade received in `threshold` seconds, request server side data
    if ts > @updated_at + threshold_in_sec
      @trigger document, 'market::charts::request_data'
      @reqK gon.market.id, @minutes

  @startDeliver = (event, data) ->
    if @interval?
      window.clearInterval @interval

    deliver = =>
      if @tradesCache.length > 0
        @deliverTrades 'trades'
      else
        @hardRefresh(300)

    @interval = setInterval deliver, 1000

  @cacheTrades = (event, data) ->
    @tradesCache = Array.prototype.concat @tradesCache, data.trades
    # console.log data.trades

  @after 'initialize', ->
    # @load()
    @on document, 'market::trades', @cacheTrades
    @on document, 'account::update', @refreshBalance
    @on document, 'market::place_order::reset_form', @resetForm
