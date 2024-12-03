#fake light module for now
var light = module('light')

light.state =  {'bri': 77, 'hue': 21, 'power': true, 'sat': 140, 'rgb': '4D3223', 'channels': [77, 50, 35]}

light.get = def () return light.state end
light.set = def (settings) print(settings) end
light.gamma10 = def (channel) print(channel) end
light.gamma8 = def (channel) print(channel) end
light.reverse_gamma10 = def (channel) print(channel) end

return light
