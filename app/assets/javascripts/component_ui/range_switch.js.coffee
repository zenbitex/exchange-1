@RangeSwitchUI = flight.component ->
    @calculatePeriod = (series) ->
        points = series.points
        if (points.length == 0)
        # no available point, unknown
            return
        else if (points.length == 1)
            if (series.hasGroupedData)
              # this length must be equal to points.length (1)
              length = series.groupedData[0].dataGroup.length
              fixedLength = [1, 5, 15, 30, 60, 120, 240, 360, 720, 1440, 4320, 10080]
              minDistance = Math.abs(length - fixedLength[0])
              index = 0
              i = 1
              while i < fixedLength.length-1
                newDistance = Math.abs(length - fixedLength[i])
                if newDistance<minDistance
                  minDistance = newDistance
                  index = i
                i++
              return fixedLength[index]
            else
              # default period time
              return 1      
        else
        # distance between two groupes
            return (points[1].x - points[0].x)/60000

    @periodUpdate = (e, series)->
        period_in_min = @calculatePeriod series
        if (period_in_min == undefined)
            period = I18n.t "private.markets.range_switch.unknown"
        else
            period = I18n.t "private.markets.range_switch.switch_" + period_in_min
        $('#range_switch_select').html period

    @after 'initialize', ->
        @on document, 'market::range_switch::period_update', @periodUpdate
