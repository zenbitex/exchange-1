window.App = angular.module('Chats', ['ngResource', 'xeditable'])
window.App.run (editableOptions)->
  editableOptions.theme = 'bs3'

App.config ["$httpProvider", (provider) ->
  provider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content")
]