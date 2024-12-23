
var gpio = module('gpio')

gpio.pin = def () return 0 end

gpio.pin_mode = def() end
gpio.digital_read = def() return 0 end

gpio.WS2812 = 1
gpio.INPUT_PULLUP = 3 # some random value

return gpio
