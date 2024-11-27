env = module("env")

import sys
sys.path().push('./tasmota_env')
sys.path().push('./tasmota')

# import all Tasmota emulator stuff to be global
import global

import load
import gpio
# import light_state
import Leds
import Leds_frame
import tasmota
import animate

return env

#
# emulate
#
var now = 0
var fname = "output.jsonl"
var duration = 3000

if (global._strip == nil)       raise "error", "global._strip is not initialized"       end

# post configure strip
global._strip.set_bri(255)          # set max brightness
global._strip.set_gamma(false)      # disable gamma

import json
var fout = open(fname, "w")
fout.write(f'{{"leds":{global._strip.pixel_count():i}}}\n')

while now < duration
  tasmota.set_millis(now)
  tasmota.fast_loop()
  
  fout.write(f'{{"t":{now:5i},"buf":"{global._strip.pixels_buffer().tohex()}"}}\n')

  now += 50   # add 50 ms step
end
fout.close()

print(f"Animation exported to '{fname}'")