# App.factory 'Screenchat', ['$resource', ($resource) ->
#   $resource '/groupchat/chats/:id', id: '@id'
#   $resource "/chats.json", {},
#     create:
#       method: "POST"
# ]
# App.factory 'ChatMessage', ['$resource', ($resource) ->
#   $resource '/groupchat/chats/:id/messages', id: '@id'
# ]