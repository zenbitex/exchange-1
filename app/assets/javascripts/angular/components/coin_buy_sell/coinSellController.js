'use strict';

coinBuySellApp.controller('coinSellController', function coinSellController($scope) {
  var scope = angular.element($("#sell")).scope();
  $scope.total_purchase = 0;
  $scope.amount = null;
  $scope.over = false;
  $scope.threshold        = gon.threshold
  $scope.price            = gon.price_sell;
  $scope.currency         = gon.trade_type;
  $scope.payment_type     = gon.payment_type;
  $scope.market           = gon.trade_type + $scope.payment_type;
  $scope.step             = gon.step;
  $scope.min              = gon.min;
  $scope.total_precision  = gon.total_precision;
  $scope.price_precision  = gon.price_precision;
  $scope.amount_precision = gon.amount_precision;
  $scope.min_warning      = true;

  if ($("body").data("lang") == "en") {
    $("label").css("font-size", "14px");
    $("#buy").css("padding-right", "5px");
    $("#buy").css("padding-left", "5px");
    $("#sell").css("padding-right", "5px");
    $("#sell").css("padding-left", "5px");
  }

  var callback = function(data) {
    if (!data || !data["sell_order_price"]) {
      return 0;
    }
    var best_price = data["sell_order_price"];
    console.log("SELL="+$scope.market + " = " + best_price);
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
    // console.log("SELL" + JSON.stringify(data));
    if (data["last_sell"] && data["last_sell"]["price"]){
      tmp["sell_order_price"] = data["last_sell"]["price"];
      callback(tmp, "taojpy");
    }
  }

  // btcjpy - xrpbtc - xrpjpy
  if ($scope.currency == 'tao') {
    var bit_station_tao = window.pusher.subscribe("market-"+$scope.market+"-global");
    bit_station_tao.bind("last_sell", callbackPriceBitstation);
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
    var message = I18n.t("buy_sell_coin.sell_confirm", {amount: $scope.amount, currency: currency});
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
    var $space = $("#space_buf2");
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
    }else {
      $scope.over = true;
      var pow =  Math.pow(10, $scope.amount_precision);
      $scope.amount = Math.floor(($scope.threshold / $scope.price) * pow) / pow;
      $scope.total_purchase = $scope.amount * $scope.price;
    }
  }
});
