# App.controller 'ScreenchatsCtrl', ['$scope', '$http', '$q',  ($scope, $http, $q) ->
#   # Attributes accessible on the view
  
#   $scope.user = {}
#   $scope.selectedScreenchat = null
#   $scope.screenchats = {}
#   $scope.chatmessages = []

#   # Screenchat.query ->
#   #   $scope.selectedScreenchat = $scope.screenchats[0]
#   #   $scope.chatmessages = ChatMessage.query(id: $scope.selectedScreenchat.id)

#   getChatName = ()->
#     $http({
#       method: 'GET'
#       url: '/get_chat_name'
#     })
#     .then (response)->
#         $scope.user.name = response.data.name

#   getScreenChats = (id)->
#     $http({
#       method: 'GET'
#       url: '/groupchat/chats/' + id
#     })
#     .then (response)->
#       $scope.screenchats = response.data
#       $scope.selectedScreenchat = response.data

#   getChatMessages = (id)->
#     $http({
#       method: 'GET'
#       url: '/groupchat/chats/' + id + '/messages'
#     })
#     .then (response)->
#       $scope.chatmessages = response.data

#   $scope.updateChatName = (name)->
#     if (name)
#       d = $q.defer()
#       $http({
#         method: 'POST'
#         url: '/update_chat_name'
#         data: {"chatname" : name}
#       })
#       .then (response)->
#         $scope.user.name = name
#         d.resolve()
#     else
#       'Can not empty'

#   # business
#   getChatName()
#   getScreenChats(1)
#   getChatMessages(1)

# ]