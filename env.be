# import all Tasmota emulator stuff to be global
import global
import load
import gpio
import ls

global.tasmota = tasmota_wasm()
load("tasmota_env/tasmota.be")

load("tasmota_env/classes_for_emulation.be")
