app.controller 'WithdrawsController', ['$scope', '$stateParams', '$http', '$gon', 'fundSourceService', 'ngDialog', ($scope, $stateParams, $http, $gon, fundSourceService, ngDialog) ->
  _selectedFundSourceId = null
  _selectedFundSourceIdInList = (list) ->
    for fs in list
      return true if fs.id is _selectedFundSourceId
    return false

  $scope.currency = currency = $stateParams.currency
  $scope.current_user = current_user = $gon.current_user
  $scope.security = $gon.security
  $scope.name = current_user.name
  $scope.account = Account.findBy('currency', $scope.currency)
  $scope.balance = $scope.account.balance
  $scope.locked  = $scope.account.locked
  $scope.currencies = $scope.currencies
  $scope.withdraw_channel = WithdrawChannel.findBy('currency', $scope.currency)
  $scope.fee_list =[432, 648]

  if $scope.currency == "btc"
    $scope.fee = FeeTrade.findBy('currency', 2).amount
  else if $scope.currency == 'xrp'
    if FeeTrade.findBy('currency', 5) != null
      $scope.fee = FeeTrade.findBy('currency', 5).amount
    else
      $scope.fee = 0
  else if $scope.currency == "jpy"
    # $scope.fee = FeeTrade.findBy('currency', 1).amount
      $scope.fee = $scope.fee_list[0]
  else if $scope.currency == 'bch'
    if FeeTrade.findBy('currency', 10) != null
      $scope.fee = FeeTrade.findBy('currency', 10).amount
    else
      $scope.fee = 0
  else if $scope.currency == 'btg'
    if FeeTrade.findBy('currency', 12) != null
      $scope.fee = FeeTrade.findBy('currency', 12).amount
    else
      $scope.fee = 0
  else if $scope.currency == 'eth'
    if FeeTrade.findBy('currency', 4) != null
      $scope.fee = FeeTrade.findBy('currency', 4).amount
    else
      $scope.fee = 0
  else if $scope.currency == 'etc'
    if FeeTrade.findBy('currency', 6) != null
      $scope.fee = FeeTrade.findBy('currency', 6).amount
    else
      $scope.fee = 0
  else if $scope.currency == 'kbr'
    if FeeTrade.findBy('currency', 11) != null
      $scope.fee = FeeTrade.findBy('currency', 11).amount
    else
      $scope.fee = 0
  $scope.bank_account = $gon.bank_account

  $scope.count_sum = ->
    if !$scope.withdrawsCtrl.withdraw.sum
      return null;

    return parseInt($scope.withdrawsCtrl.withdraw.sum) + parseInt($scope.fee);

  $scope.count_remain = ->
    remain = $scope.balance - Number($("#total_withdraw").text());
    if remain < 0
      $scope.withdrawsCtrl.withdraw.sum = parseInt($scope.account.balance - $scope.fee)

    return remain;

  setFeeJpy = (total) ->
    if !total || isNaN(total)
      return 0;
    if total < 30000
      $scope.fee = $scope.fee_list[0];
    else
      $scope.fee = $scope.fee_list[1];

  @withdrawAll = ->
    if $scope.currency == 'jpy'
      setFeeJpy($scope.account.balance)
      @withdraw.sum = parseInt($scope.account.balance - $scope.fee)
      return true
    @withdraw.sum = Number(Number($scope.account.balance - $scope.fee).toFixed(4))
    return true

  $scope.parseInteger = ->
    setFeeJpy($scope.withdrawsCtrl.withdraw.sum)
    # $scope.withdrawsCtrl.withdraw.sum = parseInt($scope.withdrawsCtrl.withdraw.sum)

  $scope.trans = (key, args)->
    I18n.t(key, args)

  $scope.selected_fund_source_id = (newId) ->
    if angular.isDefined(newId)
      _selectedFundSourceId = newId
    else
      _selectedFundSourceId

  $scope.fund_sources = ->
    fund_sources = fundSourceService.filterBy currency:currency
    # reset selected fundSource after add new one or remove previous one
    if not _selectedFundSourceId or not _selectedFundSourceIdInList(fund_sources)
      $scope.selected_fund_source_id fund_sources[0].id if fund_sources.length
    fund_sources

  # set defaultFundSource as selected
  defaultFundSource = fundSourceService.defaultFundSource currency:currency
  if defaultFundSource
    _selectedFundSourceId = defaultFundSource.id
  else
    fund_sources = $scope.fund_sources()
    _selectedFundSourceId = fund_sources[0].id if fund_sources.length

  # set current default fundSource as selected
  $scope.$watch ->
    fundSourceService.defaultFundSource currency:currency
  , (defaultFundSource) ->
    $scope.selected_fund_source_id defaultFundSource.id if defaultFundSource

  @withdraw = {}

  @createWithdraw = (currency) ->
    if !@withdraw.sum
      error_dislay "withdraw_sum", I18n.t("funds.withdraw_coin.amount_not_blank")
      return false
    withdraw_channel = WithdrawChannel.findBy('currency', currency)
    account = withdraw_channel.account()
    data = { withdraw: { member_id: current_user.id, currency: currency, sum: @withdraw.sum, destination_tag: @withdraw.tag, fund_source: _selectedFundSourceId } }

    if current_user.app_activated or current_user.sms_activated
      type = $('.two_factor_auth_type').val()
      otp  = $("#two_factor_otp").val()

      data.two_factor = { type: type, otp: otp }
      data.captcha = $('#captcha').val()
      data.captcha_key = $('#captcha_key').val()

    r = confirm(I18n.t("funds.withdraw_coin.confirm", {currency: currency, amount: @withdraw.sum}))
    if r == false
      return false
    else
      $('.form-submit > input').attr('disabled', 'disabled')
      $http.post("/withdraws/#{withdraw_channel.resource_name}", data)
        .error (responseText) ->
          error = responseText.content
          $('.withdraw_error').hide();
          switch responseText.type
            when "withdraw_error"
              error_dislay "withdraw_sum", error
            when "captcha"
              error_dislay "captcha", error
            when "two_factors_error"
              error_dislay "two_factor_otp", error
            when "limit_amount_withdraw"
              error_dislay "withdraw_sum", error
            when "limit_amount_active_account"
              error_dislay "withdraw_sum", error
            when "error_withdraw_address"
              error_dislay "withdraw_sum", error
            when "missing_destination_tag"
              error_dislay "destination_tag", error
            when "dont_have_destination_tag"
              error_dislay "destination_tag", error
            when "two_factors_error1"
              $.publish "flash", { message: error }
              $('html,body').animate({scrollTop: 0}, 300);
            else
              alert error
        .success (responseText) ->
          msg = responseText.content
          $.growl.notice({ message: msg });
        .finally =>
          @withdraw = {}
          $('.form-submit > input').removeAttr('disabled')
          $.publish 'withdraw:form:submitted'

  error_dislay = (inputId, message)->
    input = $("#" + inputId)
    parent = input.parents("div").eq(1)
    if inputId == "captcha"
      error = parent.next('.withdraw_error')
    else
      error = parent.find('.withdraw_error')
    if error.length == 0
      error = $("<span>").addClass("withdraw_error").text(message)
      if inputId == "captcha"
        error.insertAfter(parent);
        error.attr("style", "margin-left: 15px;")
      else
        parent.append(error)
      parent.click (event) ->
        error.fadeOut(500);
    else
      error.hide();
      error.fadeIn(500);
    input.focus()
    input.select()
  $scope.openFundSourceManagerPanel = ->
    if $scope.currency == $gon.fiat_currency
      template = '/templates/fund_sources/bank.html'
      className = 'ngdialog-theme-default custom-width'
    else
      if currency == 'btc'
        template = '/templates/fund_sources/coin.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'xrp'
        template = '/templates/fund_sources/xrp.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'bch'
        template = '/templates/fund_sources/bch.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'btg'
        template = '/templates/fund_sources/btg.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'eth'
        template = '/templates/fund_sources/eth.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'etc'
        template = '/templates/fund_sources/etc.html'
        className = 'ngdialog-theme-default custom-width coin'
      else if currency == 'kbr'
        template = '/templates/fund_sources/kbr.html'
        className = 'ngdialog-theme-default custom-width coin'

    ngDialog.open
      template:template
      controller: 'FundSourcesController'
      className: className
      data: {currency: $scope.currency}

  $scope.email_and_app_activated = ->
    current_user.app_activated and current_user.sms_activated and $scope.security.two_factor["Withdraw"]

  $scope.only_app_activated = ->
    current_user.app_activated and !current_user.sms_activated and !$scope.security.two_factor["Withdraw"]

  $scope.only_email_activated = ->
    current_user.sms_activated and !current_user.app_activated and !$scope.security.two_factor["Withdraw"]

  $scope.app_activated = ->
    current_user.app_activated and $scope.security.two_factor["Withdraw"]

  $scope.$watch (-> $scope.currency), ->
    setTimeout(->
      $.publish "two_factor_init"
    , 100)

]
