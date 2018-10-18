class FeeTrade extends ExchangeproModel.Model
  @configure 'FeeTrade', 'currency', 'amount', 'created_at', 'updated_at'

  @initData: (records) ->
    ExchangeproModel.Ajax.disable ->
      $.each records, (idx, record) ->
        FeeTrade.create(record)

	deposit_channels: ->
    DepositChannel.findAllBy 'currency', @currency

  withdraw_channels: ->
    WithdrawChannel.findAllBy 'currency', @currency

  deposit_channel: ->
    DepositChannel.findBy 'currency', @currency

  deposits: ->
    _.sortBy(Deposit.findAllBy('account_id', @id), (d) -> d.id).reverse()

  withdraws: ->
    _.sortBy(Withdraw.findAllBy('account_id', @id), (d) -> d.id).reverse()

  topDeposits: ->
    @deposits().reverse().slice(0,3)

  topWithdraws: ->
    @withdraws().reverse().slice(0,3)

window.FeeTrade = FeeTrade