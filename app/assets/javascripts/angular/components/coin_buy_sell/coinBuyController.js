'use strict';

coinBuySellApp.controller('coinBuyController', function coinBuyController($scope) {
  var scope = angular.element($("#buy")).scope();
  $scope.total_purchase = 0;
  $scope.amount = null;
  $scope.over = false;
  $scope.threshold        = gon.threshold
  $scope.price            = gon.price_buy;
  $scope.currency         = gon.trade_type;
  $scope.payment_type     = gon.payment_type;
  $scope.market           = gon.trade_type + $scope.payment_type;
  $scope.step             = gon.step;
  $scope.min              = gon.min;
  $scope.total_precision  = gon.total_precision;
  $scope.price_precision  = gon.price_precision;
  $scope.amount_precision = gon.amount_precision;
  $scope.min_warning      = true;

  var callback = function(data) {
    if (!data || !data["buy_order_price"]) {
      return 0;
    }
    var best_price = data["buy_order_price"];
    console.log("BUY" + $scope.market + " = " + best_price);
    scope.$apply(function(){
      scope.price = best_price;
    });
    setupTotalPurchase($scope.price * $scope.amount)
  }

  var callbackPriceKraken = function (data) {
    callback(data);
  }

  // BUY TAOBTC - TAOJPY
  var tmp = [];
  var callbackPriceBitstation = function(data){
    // console.log("BUY" +"-----------" + JSON.stringify(data));
    if (data["last_buy"] && data["last_buy"]["price"]){
      tmp["buy_order_price"] = data["last_buy"]["price"];
      callback(tmp, "taojpy");
    }
  }

  // btcjpy - xrpbtc - xrpjpy
  if ($scope.currency == 'tao') {
    console.log("market-"+$scope.market+"-global");
    var bit_station_tao = window.pusher.subscribe("market-"+$scope.market+"-global");
    bit_station_tao.bind("last_buy", callbackPriceBitstation);
  }else{
    var kraken_channel = window.pusher.subscribe("kraken-price");
    kraken_channel.bind($scope.market, callbackPriceKraken);
  }

  $scope.setPrice = function(_price){
    $scope.price = _price;
  }

  $scope.submitForm = function(event){
    if (!$scope.amount) {
      alert(I18n.t("buy_sell_coin.amount_null"));
      event.preventDefault();
      return 0;
    }

    var currency = $scope.currency.toUpperCase();
    var message = I18n.t("buy_sell_coin.buy_confirm", {amount: $scope.amount, currency: currency});
    if (!confirm(message)) {
      event.preventDefault();
    }
  }

  $scope.plusAmount = function(){
    $scope.amount += $scope.step;
  }

  $scope.minusAmount = function(){
    $scope.amount -= $scope.step;
  }

  $scope.hideSpace = function(){
    //hide all msg
    var $space = $("#space_buf");
    if (!$scope.over && !$scope.min_warning) {
      $space.removeClass("dis-none");
      $space.addClass("vis-hidden");
    }else {
      if (!$space.hasClass("dis-none")) {
        $space.addClass("dis-none");
      }
      $space.removeClass("vis-hidden");
    }
  }

  $scope.$watch('amount', function(new_val, old_val){
    if (new_val < $scope.min) {
      $scope.over = false;
      $scope.min_warning = true;
    }else{
      $scope.min_warning = false;
    }
    $scope.hideSpace();
    if (new_val < 0 || !new_val) {
      $scope.amount = 0;
      $scope.total_purchase = 0;
    }else {
    	$scope.amount = Number(new_val.toFixed($scope.amount_precision));
      var total = $scope.price * $scope.amount;
      setupTotalPurchase(total);
    }
  })

  var setupTotalPurchase = function(total){
    if (total <= $scope.threshold) {
      // $scope.over = false;
      $scope.total_purchase = total;
    } else {      
      $scope.over = true;
      var pow =  Math.pow(10, $scope.amount_precision);
      $scope.amount = Math.floor(($scope.threshold / $scope.price) * pow) / pow;
      $scope.total_purchase = $scope.amount * $scope.price;
    }
  }
});
