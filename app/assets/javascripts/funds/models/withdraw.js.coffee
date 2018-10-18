class Withdraw extends ExchangeproModel.Model
  @configure 'Withdraw', 'sn', 'account_id', 'member_id', 'currency', 'amount', 'fee', 'fund_uid', 'fund_extra',
    'created_at', 'updated_at', 'done_at', 'txid', 'blockchain_url', 'aasm_state', 'sum', 'type', 'is_submitting', 'address_url'

  constructor: ->
    super
    @is_submitting = @aasm_state == "submitting"

  @initData: (records) ->
    ExchangeproModel.Ajax.disable ->
      $.each records, (idx, record) ->
        Withdraw.create(record)

  afterScope: ->
    "#{@pathName()}"

  pathName: ->
    switch @currency
      when 'jpy' then 'banks'
      when 'btc' then 'satoshis'
      when 'tao' then 'taocoins'
      when 'xrp' then 'ripples'
      when 'bch' then 'bitcoincashes'

window.Withdraw = Withdraw
