# window.App.directive 'sockchat', ->
#   (scope, element, attrs) ->

#     scope.$watch 'selectedScreenchat', (screenchat) ->
#       if screenchat
#         if window.socket
#           console.log("Close Socket!")
#           window.socket.close()
#           $(".ajax_line").remove()


#         console.log("Open Socket!")
#         socket = new WebSocket("ws://" + window.location.host + "/chat/" + screenchat.id)
#         window.socket = socket

#         socket.onmessage = (event) ->
#           data = jQuery.parseJSON(event.data)
#           scope.$apply ()->
#             obj = {owner: {chat_name: data.username}, message : {created_at : new Date(data.date), content: data.message}}
#             scope.chatmessages.push(obj)          
#           $("#output").scrollTop(100000)

# # Click on room
# window.App.directive "clickchat", ->
#   (scope, element, attrs) ->
#     element.bind "click", ->
#       $("#screenchat-list-container li h3").removeClass(attrs.clickchat)
#       element.addClass(attrs.clickchat)

# # Input Form chat
# window.App.directive "formchat", ->
#   (scope, element, attrs) ->
#     element.bind "submit", (event)->
#       $input = undefined
#       event.preventDefault()
#       $input = element.find("input")
#       if $.trim( $input.val() ) != ''
#         socket.send JSON.stringify({
#           message: $input.val()
#         })

#       $input.val null

# # Add more room
# window.App.directive "addroom", ->
#   (scope, element, attrs) ->
#     element.bind "click", ->
#       $("form#new_room input").toggleClass("movein")