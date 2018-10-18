@LineChartUI = flight.component ->
	
	@range_name = 'market::linechart::selected_range'

	@init = (event, data) ->
		@loadFinished = false
		@$node.find('#linechart').highcharts()?.destroy()
		@loadFinished = false
		@initHighStock(data)

	@initHighStock = (data) ->
		groupingUnits = [
			[
				'minute'
				[1]
			]
			# [
			# 	'hour'
			# 	[1, 2]
			# ]
		]

		component = @
		data = data.close
	 
		@$node.find('#linechart').highcharts "StockChart",
			chart:
				events:
					load: (e) =>
						@loadFinished = true
						yAxis = $('#linechart').highcharts().yAxis[0]
						yAxis.setExtremes(yAxis.dataMin, yAxis.dataMax)
						@trigger document, 'market::range_switch::period_update', e.target.series[0]
						@trigger document, 'market::charts::load_finished', {chart: "linechart"}					
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
							yAxis = $('#linechart').highcharts().yAxis[0]
							yAxis.setExtremes(yAxis.dataMin, yAxis.dataMax)
							@trigger document, 'market::range_switch::period_update', e.target.series[0]
					afterSetExtremes: (e)=>
						if (e.trigger == "rangeSelectorButton")
							# update selected range            
							if Cookies.get(@range_name) == undefined
								Cookies.set(@range_name, 0)
							else
								Cookies.set(@range_name, e.rangeSelectorButton.index)
							yAxis = $('#linechart').highcharts().yAxis[0]
							yAxis.setExtremes(yAxis.dataMin, yAxis.dataMax)
						@trigger document, 'market::range_switch::period_update', e.target.series[0]

			series: [
				{
					id: 'linechart'
					type: 'area'
					name: 'AAPL'
					data: data
					dataGrouping:
						units: groupingUnits
						groupPixelWidth: 50

					fillColor:
							linearGradient:
									x1: 0
									y1: 0
									x2: 0
									y2: 1
							stops: [
									[0, Highcharts.getOptions().colors[0]],
									[1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
							]
				}

			]

	# @createPointOnSeries = (chart, i, px, point) ->
	# 	chart.series[i].addPoint(point, true, true)

	# @updatePointOnSeries = (chart, i, px, point) ->
	# 	if chart.series[i].points
	# 		last = chart.series[i].points[chart.series[i].points.length-1]
	# 		if px == last.x
	# 			last.update(point, false)
	# 		else
	# 			console.log "Error update on series #{i}: px=#{px} lastx=#{last.x}"

	# @updatePoint = (chart, data, i) ->
	# 	@updatePointOnSeries(chart, 0, data.close[i][0], data.close[i][1])
	# 	@createPointOnSeries(chart, 1, data.close[i][0], data.close[i][1])

	# @createPoint = (chart, data, i) ->
	# 	@createPointOnSeries(chart, 0, data.close[i][0], data.close[i])
	# 	@createPointOnSeries(chart, 1, data.close[i][0], data.close[i])
	# 	chart.redraw(true)

  @updatePoint = (chart, point) ->
    series = chart.get('linechart')
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
    series = chart.get('linechart')
    if series
      _data = series.options.data
      _data.push(point)
      series.setData(_data)

  @process = (chart, data) ->
    series = chart.get('linechart')
    current_position = series.options.data.length - 1
    if current_position >= 0
      current_point = series.options.data[current_position]
      for i in [0..(data.close.length-1)]      
        if data.close[i][0] > current_point[0]          
          @createPoint chart, data.close[i]
        else
          @updatePoint chart, data.close[i]

	@updateByTrades = (event, data) ->
		chart = @$node.find('#linechart').highcharts()
		if @loadFinished
			@process chart, data

	@after 'initialize', ->
		@on document, 'market::linechart::data', @init
		@on document, 'market::linechart::trades', @updateByTrades