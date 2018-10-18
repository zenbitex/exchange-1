@OrderBookUI = flight.component ->

  @maxRow = 20

  @init = ()=>
    @order_books = []
    for i in [0..@maxRow-1]
      @order_books.push({id: i, volume: 0, price: 0})
    scope = angular.element($("#order_book")).scope();
    scope.$apply ()=>
        scope.order_books = @order_books

  @check = () =>
    @loaded = true
    if (@pendingEvent)
      @update @pendingEvent[0], @pendingEvent[1]

  @pendingUpdate = (event, data)=>
    if (@loaded)
      @update event, data
    else
      @pendingEvent = [event, data]

  @update = (event, data) ->
    @books = []
    bids = []
    asks = []
    # -- append to array then sort descending

    if data.asks.length > @maxRow/2
      data.asks = data.asks.slice(0, @maxRow/2)

    i = 0
    while i < data.asks.length
      item = {volume: data.asks[i][1], price: data.asks[i][0], isBid: false}
      asks.push(item)
      i++

    asks.sort (a, b)->
      return a.price - b.price

    i = data.asks.length
    while i < @maxRow/2
      asks.push({volume: 0, price: 0, isBid: false})
      i++

    if data.bids.length > @maxRow/2
      data.bids = data.bids.slice(0, @maxRow/2)

    i = 0
    while i < data.bids.length
      item = {volume: data.bids[i][1], price: data.bids[i][0], isBid: true}
      bids.push(item)
      i++

    i = data.bids.length
    while i < @maxRow/2
      bids.push({volume: 0, price: 0, isBid: true})
      i++

    bids.sort (a, b)->
      return b.price - a.price;

    i = 0
    while i < @maxRow/2
      @books.push(asks[@maxRow/2-1-i])
      @books[i]['id'] = i
      i++

    i = 0
    while i < @maxRow/2
      @books.push(bids[i])
      @books[i + @maxRow/2]['id'] = i + @maxRow/2
      i++

    # -- find positions that need update
    # updatePositions = []
    # i = 0
    # console.log books
    # while i < @maxRow
    #   if @order_books[i].front
    #     if (books[i].price!=@order_books[i].frontPrice) || (books[i].volume!=@order_books[i].frontVolume) || (books[i].isBid!=@order_books[i].frontIsBid)
    #       updatePositions.push(i)
    #   else
    #     if (books[i].price!=@order_books[i].backPrice) || (books[i].volume!=@order_books[i].backVolume) || (books[i].isBid!=@order_books[i].backIsBid)
    #       updatePositions.push(i)
    #   i++
    #
    # delay = 0
    # length_update = updatePositions.length
    #
    # for i in updatePositions
    #   # -- update data in @order_books
    #   delay++
    #   @order_books[i].delay = delay
    #   if @order_books[i].front
    #     @order_books[i].backVolume = books[i].volume
    #     @order_books[i].backPrice = books[i].price
    #     @order_books[i].backIsBid = books[i].isBid
    #     $('#flip_'+i).attr('class', "flipped-to-back")
    #   else
    #     @order_books[i].frontVolume = books[i].volume
    #     @order_books[i].frontPrice = books[i].price
    #     @order_books[i].frontIsBid = books[i].isBid
    #     $('#flip_'+i).attr('class', "flipped-to-front")
    #   @order_books[i].front = !@order_books[i].front
    #
    #   if (delay == 1 && i >= 10) || (delay == length_update &&  i < 10)
    #     effect = $("<div class='effect'></div>")
    #     $('#flip_'+ i).parent().find('.effect').remove()
    #     effect.insertAfter $('#flip_'+ i)
    #     effect.fadeOut(2000)

    # effect = $("<div class='effect'></div>")
    # $('#flip_9').parent().find('.effect').remove()
    # $('#flip_9').parent().append(effect)
    # effect.fadeOut(2000)

    #show effect
    diff = []    
    if @preview_books
      for i in [0..@books.length-1]
        exist = false
        now = @books[i]
        for j in [0..@preview_books.length-1]
          prev = @preview_books[j]
          if ((prev['volume'] == now['volume']) && (prev['price'] == now['price'])) || (now['price'] == 0)
            exist = true
            break
        if !exist
          @books[i]['change'] = true


    # -- apply data change on #order_book
    scope = angular.element($("#order_book")).scope();
    if scope
      scope.$apply ()=>
        console.log @books
        @preview_books = @books
        scope.order_books = @books


  @after 'initialize', ->
    @init()
    @on document, 'market::order_book::update', @pendingUpdate
    @on document, 'ready', @check

    # @on @select('fade_toggle_depth'), 'click', =>
    #   @trigger 'market::depth::fade_toggle'

    # $('.asks').on 'click', 'tr', (e) =>
    #   i = $(e.target).closest('tr').data('order')
    #   @placeOrder $('#bid_entry'), _.extend(@computeDeep(e, gon.asks), type: 'ask')
    #   @placeOrder $('#ask_entry'), {price: BigNumber(gon.asks[i][0]), volume: BigNumber(gon.asks[i][1])}

    # $('.bids').on 'click', 'tr', (e) =>
    #   i = $(e.target).closest('tr').data('order')
    #   @placeOrder $('#ask_entry'), _.extend(@computeDeep(e, gon.bids), type: 'bid')
    #   @placeOrder $('#bid_entry'), {price: BigNumber(gon.bids[i][0]), volume: BigNumber(gon.bids[i][1])}
