@PlaceOrderUI = flight.component ()->

  @attributes
    formSel: 'form'
    successSel: '.status-success'
    infoSel: '.status-info'
    dangerSel: '.status-danger'
    submitButton: ':submit'
    currentBalance: '.total-hint'

    priceSel: 'input[id$=price]'
    volumeSel: 'input[id$=volume]'
    totalSel: 'input[id$=total]'

  @showTotalBalance = ()->
    @select('currentBalance').show()

  @hideTotalBalance = ()->
    @select('currentBalance').hide()

  @cleanMsg = ->
    @select('successSel').text('')
    @select('infoSel').text('')
    @select('dangerSel').text('')

  @resetForm = () ->
    @trigger document, 'market::place_order::reset_form'

  @disableSubmit = ()->
    $('submitButton').addClass('disabled').attr('disabled', 'disabled')

  @enableSubmit = ->
    $('submitButton').removeClass('disabled').removeAttr('disabled')

  @beforeSend = (event, jqXHR) ->
    if true #confirm(@confirmDialogMsg())
      @disableSubmit()
    else
      jqXHR.abort()

  @handleSuccess = (event, data) ->
    @cleanMsg()
    label = @select('successSel').append(JST["templates/hint_order_success"]({msg: data.message}))
    label.toggleClass('hide-out')
    window.setTimeout ()->
      label.toggleClass('hide-out')
    , 2000
    @resetForm(event)
    window.sfx_success()
    @enableSubmit()

  @handleError = (event, data) ->
    @cleanMsg()
    ef_class = 'shake shake-constant hover-stop'

    try
      json = JSON.parse(data.responseText)
    catch error
      json = data.responseText

    label = @select('dangerSel').append(JST["templates/hint_order_warning"]({msg: if json.message then json.message else json}))
    label.toggleClass('hide-out')
    window.setTimeout ()->
      label.toggleClass('hide-out')
    , 3500
    window.sfx_warning()
    @enableSubmit()

  @after 'initialize', ()->
    @on @select('formSel'), 'ajax:beforeSend', @beforeSend
    @on @select('formSel'), 'ajax:success', @handleSuccess
    @on @select('formSel'), 'ajax:error', @handleError
    @on @select('priceSel'), 'focus', @showTotalBalance
    @on @select('priceSel'), 'focusout', @hideTotalBalance
    @on @select('volumeSel'), 'focus', @showTotalBalance
    @on @select('volumeSel'), 'focusout', @hideTotalBalance
