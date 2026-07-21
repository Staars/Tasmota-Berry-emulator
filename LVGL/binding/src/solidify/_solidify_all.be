path = nil
ctypes_bytes_dyn = nil
tasmota = nil
ccronexpr = nil
gpio = nil
light = nil
webclient = nil
load = nil
MD5 = nil
lv = nil
light_state = nil
lv_clock = nil
lv_clock_icon = nil
lv_signal_arcs = nil
lv_signal_bars = nil
lv_wifi_arcs_icon = nil
lv_wifi_arcs = nil
lv_wifi_bars_icon = nil
lv_wifi_bars = nil
_lvgl = nil
cb = nil

import global
import solidify
import string
import re

# ---- lv.be ----
var f = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/embedded/lv.be")
var src = f.read()
f.close()
var compiled = compile(src)
compiled()

var fout = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/solidify/solidified_lv.h", "w")
fout.write("/* Solidification of lv.h */\n")
fout.write("/********************************************************************\\\n")
fout.write("* Generated code, don't edit                                         *\n")
fout.write("\\********************************************************************/\n")
fout.write('#include "be_constobj.h"\n')
solidify.dump(global.lv_module_init, true, fout)
fout.write("/********************************************************************/\n")
fout.write("/* End of solidification */\n")
fout.close()


# ---- lvgl_glob.be ----
var f = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/embedded/lvgl_glob.be")
var src = f.read()
f.close()
var compiled = compile(src)
compiled()

var fout = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/solidify/solidified_lvgl_glob.h", "w")
fout.write("/* Solidification of lvgl_glob.h */\n")
fout.write("/********************************************************************\\\n")
fout.write("* Generated code, don't edit                                         *\n")
fout.write("\\********************************************************************/\n")
fout.write('#include "be_constobj.h"\n')
solidify.dump(global.LVGL_glob, true, fout)
fout.write("/********************************************************************/\n")
fout.write("/* End of solidification */\n")
fout.close()


# ---- lvgl_extra.be ----
var f = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/embedded/lvgl_extra.be")
var src = f.read()
f.close()
var compiled = compile(src)
compiled()

var fout = open("/Users/christianbaars/Developer/Tasmota-Berry-emulator/LVGL/binding/src/solidify/solidified_lvgl_extra.h", "w")
fout.write("/* Solidification of lvgl_extra.h */\n")
fout.write("/********************************************************************\\\n")
fout.write("* Generated code, don't edit                                         *\n")
fout.write("\\********************************************************************/\n")
fout.write('#include "be_constobj.h"\n')
solidify.dump(global.lv_extra, true, fout)
fout.write("/********************************************************************/\n")
fout.write("/* End of solidification */\n")
fout.close()

