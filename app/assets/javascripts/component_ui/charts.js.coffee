@ChartsUI = flight.component ()->

	@mask = ->
    	@$node.find('.mask').show()

  	@unmask = ->
    	@$node.find('.mask').hide()

    @checkUnmask = (e, data)->    	
    	if (data.chart == "candlestick")
    		@candlestickLoaded = true;
    	if (data.chart == "linechart")
    		@linechartLoaded = true;

    	if (@candlestickLoaded && @linechartLoaded)
    		@unmask()

	@after 'initialize', ->
		@on document, 'market::charts::request_data', @mask
		@on document, 'market::charts::load_finished', @checkUnmask