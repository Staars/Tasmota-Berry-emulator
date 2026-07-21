# import all Tasmota emulator stuff to be global
import global
import load
import gpio
import ls
import la
import light

# LVGL
import lv
import lv_tasmota
lv.start = lv_tasmota.start
lv.font_montserrat = lv_tasmota.font_montserrat
lv.montserrat_font = lv_tasmota.montserrat_font
lv.seg7_font = lv_tasmota.seg7_font

global.tasmota = tasmota_wasm()
load("tasmota_env/trigger_class.be")
load("tasmota_env/tasmota.be")

load("tasmota_env/classes_for_emulation.be")
load("tasmota_env/wc.be")
load("tasmota_env/lv_tasmota_widgets.be")
