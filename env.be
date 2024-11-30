# import all Tasmota emulator stuff to be global
import global
import load
import gpio

global.tasmota = tasmota_wasm()
load("tasmota_env/tasmota.be")
