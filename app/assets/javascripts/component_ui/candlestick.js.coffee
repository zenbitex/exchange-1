@CandlestickUI = flight.component ->

  @range_name = 'market::candlestick::selected_range'

  @init = (event, data) ->
    @loadFinished = false
    @running = true
    @$node.find('#candlestick_chart').highcharts()?.destroy()
    @initHighStock(data)

  @initHighStock = (data) ->
    groupingUnits = [
      [
        'minute'
        [1, 5, 15]
      ]
      [
        'hour'
        [1, 2]
      ]
    ]

    # populate data
    ohlc = []
    volume = []
    dataLength = data.candlestick.length
    i = 0
    while i < dataLength
      ohlc.push [
        data.candlestick[i][0]
        data.candlestick[i][1]
        data.candlestick[i][2]
        data.candlestick[i][3]
        data.candlestick[i][4]
      ]
      volume.push [
        data.volume[i].x
        data.volume[i].y
      ]
      i += 1

    component = @
   
    @$node.find('#candlestick_chart').highcharts "StockChart",
      chart:
        events:
          load: (e) =>
            @loadFinished = true            
            @trigger document, 'market::charts::load_finished', {chart: "candlestick"}
        animation: true
        marginTop: 20
        
      credits:
        enabled: false

      tooltip:
        split: true

      rangeSelector:
        allButtonsEnabled: true
        buttons: [
          {
            index: 0
            type: 'hour'
            count: 1
            text: '1h'
          }
          {
            index: 1
            type: 'hour'
            count: 6
            text: '6h'
          }        
          {
            index: 2
            type: 'hour'
            count: 12
            text: '12h'
          }
          {
            index: 3
            type: 'day'
            count: 1
            text: '1d'
          }
          {
            index: 4
            type: 'all'
            count: 1
            text: 'all'
          }
        ]
        selected: if (Cookies.get(@range_name) == undefined) then 1 else Cookies.get(@range_name)

      xAxis:
        type: 'datetime'
        minRange: 1800000 # setting this equal to min 'rangeSelector' button may cause undefined behavior
        events:
          setExtremes: (e)=>
            if (e.trigger == "navigator")
              @trigger document, 'market::range_switch::period_update', e.target.series[0]
          afterSetExtremes: (e)=>
            if (e.trigger == "rangeSelectorButton")
              # update selected range            
              if Cookies.get(@range_name) == undefined
                Cookies.set(@range_name, 0)
              else
                Cookies.set(@range_name, e.rangeSelectorButton.index)
            @trigger document, 'market::range_switch::period_update', e.target.series[0]

      yAxis: [
        {
            labels:
                align: 'right'
                x: -3
            height: '100%'
            lineWidth: 2
        }
      ]

      series: [
        {
          id: 'candlestick'     
          type: 'candlestick'
          name: 'OHLC'
          data: ohlc
          dataGrouping:
            units: groupingUnits
            groupPixelWidth: 50
        }
      ]

  @updatePoint = (chart, point) ->
    series = chart.get('candlestick')
    if series
      _data = series.options.data
      # make changes to last point
      lastPoint = _data[_data.length-1]
      if (lastPoint[0] == point[0])
        # do updating
        _data[_data.length-1] = point
      else
        # exception
        console.log "Exception: timestamps deviation between update points"

      # update series
      series.setData(_data)

  @createPoint = (chart, point) ->
    series = chart.get('candlestick')
    if series
      _data = series.options.data
      _data.push(point)
      series.setData(_data)

  @process = (chart, data) ->
    series = chart.get('candlestick')
    current_position = series.options.data.length - 1
    if current_position >= 0
      current_point = series.options.data[current_position]
      for i in [0..(data.candlestick.length-1)]      
        if data.candlestick[i][0] > current_point[0]          
          @createPoint chart, data.candlestick[i]
        else
          @updatePoint chart, data.candlestick[i]

  @updateByTrades = (event, data) ->
    chart = @$node.find('#candlestick_chart').highcharts()
    if (@loadFinished)
      @process chart, data

  @after 'initialize', ->
    @on document, 'market::candlestick::data', @init
    @on document, 'market::candlestick::trades', @updateByTrades