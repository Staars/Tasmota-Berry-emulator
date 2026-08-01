# Tasmota emulator - built-in console commands registered via tasmota.add_cmd
import string

# ----- Pixels ----------------------------------------------------------------
# ESP32 (addressable LEDs) only. Syntax:
#   Pixels <pixels>[,<reverse>,<height>,<alternate>]
#   pixels   1..512 (number of pixels in strip or ring)
#   reverse  0..1   (direction, not implemented yet, stored for later use)
#   height   1..n   (matrix height, default 1)
#   alternate 0..1  (zig-zag wiring, default 0)
# A bare `Pixels` returns the currently stored configuration.
# Config-only in the emulator: no LED buffer or UI is updated.

def _pixels_get()
  var cfg = global.tasmota._pixels
  if cfg == nil
    cfg = {'Pixels': 256, 'PixelsReverse': 0, 'PixelsHeight': 8, 'PixelsAlternate': 1}
    global.tasmota._pixels = cfg
  end
  return {
    'Pixels': cfg['Pixels'],
    'PixelsReverse': cfg['PixelsReverse'],
    'PixelsHeight': cfg['PixelsHeight'],
    'PixelsAlternate': cfg['PixelsAlternate'],
  }
end

def _pixels_cmd(cmd, idx, payload, payload_json)
  if type(payload) != 'string' || size(payload) == 0
    return _pixels_get()
  end
  var parts = string.split(payload, ",")
  var n = int(tasmota._cmd_trim(parts[0]))
  if n < 1  n = 1 end
  if n > 512  n = 512 end
  var rev = 0
  if size(parts) > 1
    rev = int(tasmota._cmd_trim(parts[1]))
    if rev < 0  rev = 0 end
    if rev > 1  rev = 1 end
  end
  var height = 8
  if size(parts) > 2
    height = int(tasmota._cmd_trim(parts[2]))
    if height < 1  height = 1 end
  end
  var alt = 1
  if size(parts) > 3
    alt = int(tasmota._cmd_trim(parts[3]))
    if alt < 0  alt = 0 end
    if alt > 1  alt = 1 end
  end
  global.tasmota._pixels = {
    'Pixels': n,
    'PixelsReverse': rev,
    'PixelsHeight': height,
    'PixelsAlternate': alt,
  }
  return _pixels_get()
end

tasmota.add_cmd('Pixels', _pixels_cmd)

# ----- legacy SetOption -------------------------------------------------------
# Keeps the historical emulator behaviour: `tasmota.cmd("so65")` -> {"SetOption65":"ON"}

def _setoption_cmd(cmd, idx, payload, payload_json)
  if idx > 0
    return {f"SetOption{idx}": 'ON'}
  end
  tasmota.resp_cmnd_error()
end

tasmota.add_cmd('so', _setoption_cmd)
tasmota.add_cmd('setoption', _setoption_cmd)
