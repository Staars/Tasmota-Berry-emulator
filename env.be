
import sys
sys.path().push('./tasmota_env')
sys.path().push('./tasmota')

# import all Tasmota emulator stuff to be global
import global
import load
import gpio

global.tasmota = tasmota_wasm()
load("tasmota_env/tasmota.be")

import light_state
import Leds
import Leds_frame
import animate
