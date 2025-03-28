#
# Example for M5Stack Led Matrix
# 5 x 5 WS2812
#
import animate

var strip = Leds(5 * 5, gpio.pin(gpio.WS2812, 0))
var anim = animate.core(strip)
strip.set_bri(255)          # set max brightness
anim.set_back_color(0x2222AA)
var pulse = animate.pulse(0xFF4444, 2, 1)
var osc1 = animate.oscillator(-3, 26, 5000, animate.COSINE)
osc1.set_cb(pulse, pulse.set_pos)

# animate color of pulse
var palette = animate.palette(animate.PALETTE_STANDARD_TAG, 30000)
palette.set_cb(pulse, pulse.set_color)

anim.start()
