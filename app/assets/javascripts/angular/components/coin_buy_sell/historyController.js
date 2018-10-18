'use strict';

coinBuySellApp.controller('historyController', function historyController($scope, $http, $filter) {
  $scope.page = 1;
  $scope.loadHistory = function () {
    $("#loading").removeClass("hidden");
    $scope.page ++;
    $http({
      method: 'GET',
      url: '/coin_trade/load_history',
      params: {page: $scope.page}
    }).then(function successCallback(response) {
      var $tbody  = $(".history tbody");
      angular.forEach(response.data, function(h) {
        $tbody.append($("<tr>")
                .append($("<th>").text(h.trade_type))
                .append($("<th>").addClass("uppercase").text(h.currency))
                .append($("<th>").addClass("uppercase").text(h.payment_type))
                .append($("<th>").text(h.price))
                .append($("<th>").text(h.amount))
                .append($("<th>").text(h.total))
                .append($("<th>").text($filter('date')(new Date(h.created_at), 'yyyy:mm:dd hh:mm:ss')))
        );
      });
      $("#loading").addClass("hidden");
    }, function errorCallback(response) {
      console.log(response);
    });
  };

  function parseTwitterDate(text) {
    return new Date(Date.parse(text.replace(/( +)/, ' UTC$1')));
  }

});
