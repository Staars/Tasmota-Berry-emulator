#fake mqtt module for now
var mqtt = module('mqtt')

mqtt.publish = def () end
mqtt.subscribe = def () end
mqtt.unsubscribe = def () end
mqtt.connected = def () return false end

return mqtt
