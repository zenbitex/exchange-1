app.controller 'DepositHistoryController', ($scope, $stateParams, $http) ->
  ctrl = @
  $scope.predicate = '-id'
  @currency = $stateParams.currency
  @account = Account.findBy('currency', @currency)
  @deposits = @account.deposits()
  $scope.balance = $scope.account.balance
  $scope.locked  = $scope.account.locked
  @newRecord = (deposit) ->
    if deposit.aasm_state == "submitting" then true else false

  @noDeposit = ->
    @deposits.length == 0

  @refresh = ->
    @deposits = @account.deposits()
    $scope.$apply()

  @cancelDeposit = (deposit) ->
    deposit_channel = DepositChannel.findBy('currency', deposit.currency)
    if confirm I18n.t("funds.deposit_coin.cancle")
      $http.delete("/deposits/#{deposit_channel.resource_name}/#{deposit.id}")
      .error (responseText) ->
        $.publish 'flash', { message: responseText }

  @canCancel = (state) ->
    ['submitting'].indexOf(state) > -1

  do @event = ->
    Deposit.bind "create update destroy", ->
      ctrl.refresh()
