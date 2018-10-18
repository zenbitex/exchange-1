app.service 'feetradeService', ['$filter', '$gon', ($filter, $gon) ->

  filterBy: (filter) ->
    $filter('filter')($gon.fees, filter)

  findBy: (filter) ->
    result = @filterBy filter
    if result.length then result[0] else null

]
