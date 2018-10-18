pusher = new Pusher gon.pusher.key,
  encrypted: gon.pusher.encrypted
  # wsHost: gon.pusher.wsHost
  # wsPort: gon.pusher.wsPort
  # wssPort: gon.pusher.wssPort

# console.log(gon.pusher.key, gon.pusher.encrypted)

window.pusher = pusher
$(window).on 'beforeunload', ()->
	if (window.pusher && window.pusher.connection.state == "connected")
		window.pusher.disconnect()
