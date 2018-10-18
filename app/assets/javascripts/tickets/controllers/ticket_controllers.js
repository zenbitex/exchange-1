ticket.controller("ticketCtrl", function($scope, $http, $location) {
    $scope.firstName = "John";
    $scope.lastName = "Doe";
    $scope.replyContent = "";
    $scope.ticketTitle = "";
    $scope.ticketContent = "";
    $scope.ticketIdFirstLoad = 0;
    $scope.unread = gon.unread;
    $scope.tickets_open = gon.tickets_open;
    $scope.tickets_closed = gon.tickets_closed;

    $scope.ticketShow = function(id){
      $http({
        method: 'GET',
        url: '/tickets/'+id+'.json'
      }).then(function successCallback(response) {
          $location.url(id);          
          $scope.ticket = response.data.ticket;
          $scope.comments = response.data.comments;
          $scope.unread = response.data.unread;
        }, function errorCallback(response) {

        });
    }

    $scope.reply = function () {
      $http({
        method: 'POST',
        url: '/tickets/'+$scope.ticket.id+'/comments',
        data: {content: $scope.replyContent}
      }).then(function successCallback(response) {
          console.log(response.data);
          $scope.replyContent = "";
          $scope.comments = response.data;
        }, function errorCallback(response) {

        });
    }

    $scope.addNewTicket = function () {
      $http({
        method: 'POST',
        url: '/tickets',
        data:{title: $scope.ticketTitle, content: $scope.ticketContent}
      }).then(function successCallback(response) {
          $scope.ticketShow(response.data.ticket_id);
          $('#new_ticket_modal').modal('hide');
          $scope.tickets_open = response.data.tickets_open;
          $scope.tickets_closed = response.data.tickets_closed;
          $scope.ticketTitle = "";
          $scope.ticketContent = "";
        }, function errorCallback(response) {

        });
    }

    $scope.isUnreadList = function (id) {
      if($scope.unread.indexOf(id) !== -1) {
        return true;
      }
      return false;
    }

    //First Page Load
    if ($location.path()) {
      $scope.ticketIdFirstLoad = $location.path().substring(1);
      if (!isNaN($scope.ticketIdFirstLoad)) {
        $scope.ticketShow($scope.ticketIdFirstLoad);
      }
    }
});
