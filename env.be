# import all Tasmota emulator stuff to be global
import global
import load
import gpio
import ls
import la
import light


global.tasmota = tasmota_wasm()
load("tasmota_env/trigger_class.be")
load("tasmota_env/tasmota.be")

load("tasmota_env/classes_for_emulation.be")
load("tasmota_env/wc.be")
