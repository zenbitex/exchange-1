class WithdrawChannel extends ExchangeproModel.Model
  @configure 'WithdrawChannel', 'key', 'currency', 'resource_name'

  @initData: (records) ->
    ExchangeproModel.Ajax.disable ->
      $.each records, (idx, record) ->
        WithdrawChannel.create(record)

  account: ->
    Account.findBy('currency', @currency)

window.WithdrawChannel = WithdrawChannel
