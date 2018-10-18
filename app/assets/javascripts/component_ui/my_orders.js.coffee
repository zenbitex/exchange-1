@MyOrdersUI = flight.component ->
  flight.compose.mixin @, [ItemListMixin]

  $.marketApp.controller 'MyOrdersController', ['$scope', ($scope) =>

    dismissPopup = ()->
      popup = $('#myorder_menu')
      popup.css({
          display: "none"
      })

    $scope.removeOrder = ()=>
      if @removeObject
        dismissPopup()
        if confirm @removeObject.confirmMessage
          $.ajax @removeObject.url, {method: @removeObject.method}

    $scope.removeOrders = (url, message)=>
      dismissPopup()
      if confirm message
        $.ajax url, {method: 'post'}
  ]

  @init = ()=>
    @popup = $('#myorder_menu')

  @getTemplate = (order) -> $(JST["templates/order_active"](order))

  @orderHandler = (event, order) ->
    return unless order.market == gon.market.id
    switch order.state
      when 'wait'
        @addOrUpdateItem order
      when 'cancel'
        @removeItem order.id
      when 'done'
        @removeItem order.id

  @dismissPopupMenu = (e)=>
    @popup.css({
        display: "none"
    })

  @showPopupMenu = (event, options) =>
    if event.type == 'contextmenu'
      event.preventDefault()

    # top_pos = if event.clientY then (event.clientY + 'px') else (options.clientY + 'px')
    # left_pos = if event.clientX then (event.clientX + 'px') else (options.clientX + 'px')
    top_pos = options.clientY + 20
    left_pos = options.clientX + 30
    @popup.css({
        position: "absolute"
        display: "block"
        top: top_pos
        left: left_pos
    })

    tr = $(event.target).parents('tr')
    @removeObject = {
      confirmMessage: formatter.t('place_order')['confirm_cancel']
      url: formatter.market_url gon.market.id, tr.data('id')
      method: 'delete'
    }


  @.after 'initialize', ->
    @init()
    @on document, 'order::wait::populate', @populate
    @on document, 'order::wait order::cancel order::done', @orderHandler
    @on document, 'order::show_popupmenu', @showPopupMenu
    @on document, 'click', @dismissPopupMenu
