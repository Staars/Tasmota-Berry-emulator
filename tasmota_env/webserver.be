# EMULATOR STUB: webserver
#
# This module only keeps Tasmota extensions that reference `webserver` loadable.
# The emulator does not currently route HTTP requests or capture responses.
# Replace these no-op methods if webserver emulation becomes necessary.
var webserver = module('webserver')

webserver.HTTP_GET = 1
webserver.HTTP_POST = 2

webserver.on = def (path, callback, method) end
webserver.remove_route = def (path, method) end
webserver.arg = def (name) end
webserver.content_open = def (status, mime) end
webserver.content_send = def (body) end
webserver.content_close = def () end

return webserver
