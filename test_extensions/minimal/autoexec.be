import introspect
var ext = introspect.module("minimal_driver", true)
tasmota.add_extension(ext)