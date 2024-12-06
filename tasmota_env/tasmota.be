# Tasmota emulator - lightweitght for Leds animation

import global

class Tasmota : tasmota_wasm
  # var _millis           # emulate millis from Tasmota
  var _fl               # fast_loop
  var _drivers
  var _rules
  var _timers         # holds both timers and cron
  var _crons
  var _ccmd

  # def init()
  #   self._millis = 1
  # end

  static def scale_uint(inum, ifrom_min, ifrom_max, ito_min, ito_max)
    if (ifrom_min >= ifrom_max)
      return (ito_min > ito_max ? ito_max : ito_min)  # invalid input, return arbitrary value
    end
    
    var num = inum
    var from_min = ifrom_min
    var from_max = ifrom_max
    var to_min = ito_min
    var to_max = ito_max

    # check source range
    num = (num > from_max ? from_max : (num < from_min ? from_min : num))

    # check to_* order
    if (to_min > to_max)
      # reverse order
      num = (from_max - num) + from_min
      to_min = ito_max
      to_max = ito_min
    end

    # short-cut if limits to avoid rounding errors
    if (num == from_min) return to_min  end
    if (num == from_max) return to_max  end
    
    var result
    if ((num - from_min) < 0x8000)
      if (to_max - to_min > from_max - from_min)
        var numerator = (num - from_min) * (to_max - to_min) * 2
        result = ((numerator / (from_max - from_min)) + 1 ) / 2 + to_min
      else
        var numerator = ((num - from_min) * 2 + 1) * (to_max - to_min + 1)
        result = numerator / ((from_max - from_min + 1) * 2) + to_min
      end
    else
      var numerator = (num - from_min) * (to_max - to_min + 1)
      result = numerator / (from_max - from_min) + to_min
    end

    return (result > to_max ? to_max : (result < to_min ? to_min : result))
  end

  static def scale_int(num, from_min, from_max, to_min, to_max)
    # guard-rails
    if (from_min >= from_max)
      return (to_min > to_max ? to_max : to_min)  # invalid input, return arbitrary value
    end

    var from_offset = 0
    if (from_min < 0)
      from_offset = - from_min
    end
    var to_offset = 0
    if (to_min < 0)
      to_offset = - to_min
    end
    if (to_max < (- to_offset))
      to_offset = - to_max
    end

    return _class.scale_uint(num + from_offset, from_min + from_offset, from_max + from_offset, to_min + to_offset, to_max + to_offset) - to_offset
  end

  def cmd(c)
    print("cmd - fake method")
    import string
    if string.find(c,"so") == 0
      var s = string.replace(c,"so","")
      s = f"SetOption{int(s)}"
      return {s: 'ON'}
    end
  end

  def add_rule()
    print("add_rule - fake method")
  end

  def set_timer(delay,f,id)
    self.check_not_method(f)
    if self._timers == nil
      self._timers=[]
    end
    self._timers.push(Trigger(self.millis(delay),f,id))
  end

  def yield()
    print("yield - fake method")
  end

  def rtc(key)
    import time
    var ts = time.time()
    if key
      return {'local': ts, 'utc': ts, 'timezone': 60, 'restart': ts}[key]
    else
      return {'local': ts, 'utc': ts, 'timezone': 60, 'restart': ts}
    end
  end

  def time_dump(ts)
    import time
    return time.dump(ts)
  end

  def strftime(sformat,ts)
    import string
    var td = self.time_dump(ts)
    var s = sformat
    string.replace(s,"%H",str(td["hour"]))
    string.replace(s,"%M",str(td["min"]))
    string.replace(s,"%S",str(td["sec"]))
    string.replace(s,"%Y",str(td["year"]))
    string.replace(s,"%m",str(td["month"]))
    string.replace(s,"%d",str(td["day"]))
    print("fake - strftime ... does not work")
    return s
  end

  def read_sensors()
    return {'ANALOG': {'A1': 2300, 'A1': 2300, 'Illuminance1': 100}}
  end

  def wifi()
    print("fake - wifi")
    return {'mac': 'aa:bb:cc:22:11:03', 'quality': 100, 'rssi': -47, 'ip': '192.168.1.102', 'up': false}
  end

  # fast_loop() is a trimmed down version of event() called at every Tasmota loop iteration
  # it is optimized to be as fast as possible and reduce overhead
  # there is no introspect, closures must be registered directly
  def fast_loop()
    var fl = self._fl
    if !fl return end     # fast exit if no closure is registered (most common case)

    # iterate and call each closure
    var i = 0
    var sz = size(fl)
    while i < sz
      # note: this is not guarded in try/except for performance reasons. The inner function must not raise exceptions
      fl[i]()
      i += 1
    end
  end

  # check that the parameter is not a method, it would require a closure instead
  def check_not_method(f)
    import introspect
    if type(f) != 'function'
      raise "type_error", "BRY: argument must be a function"
    end
    if introspect.ismethod(f) == true
      raise "type_error", "BRY: method not allowed, use a closure like '/ args -> obj.func(args)'"
    end
  end

  def add_fast_loop(cl)
    self.check_not_method(cl)
    if self._fl == nil
      self._fl = []
    end
    if type(cl) != 'function' raise "value_error", "argument must be a function" end
    global.fast_loop_enabled = 1      # enable fast_loop at global level: `TasmotaGlobal.fast_loop_enabled = true`
    self._fl.push(cl)
  end

  def remove_fast_loop(cl)
    if !self._fl return end
    var idx = self._fl.find(cl)
    if idx != nil
      self._fl.remove(idx)
    end
  end

  def sine_int(i)
    import math

    var x = i / 16384.0 * math.pi
    var y = math.sin(x)
    var r = int(y * 4096)
    return r
  end

  def time_str(time_stamp)
    import time
    var tm = time.dump(time_stamp)
    return format("%04d-%02d-%02dT%02d:%02d:%02d", tm['year'], tm['month'], tm['day'], tm['hour'], tm['min'], tm['sec'])
  end

  def gc()
    import gc
    gc.collect()
    return gc.allocated()
  end

  def add_driver(d)
    if type(d) != 'instance'
      raise "value_error", "instance required"
    end
    if self._drivers
      if self._drivers.find(d) == nil     # add only if not already added
        self._drivers.push(d)
      end
    else
      self._drivers = [d]
    end
  end

  def remove_driver(d)
    if self._drivers
      var idx = self._drivers.find(d)
      if idx != nil
        self._drivers.pop(idx)
      end
    end
  end

  # run every 50ms tick
  def run_deferred()
    if self._timers
      var i=0
      while i < self._timers.size()
        var trigger = self._timers[i]

        if self.time_reached(trigger.trig)
          var f = trigger.f
          self._timers.remove(i)      # one shot event
          f()
        else
          i += 1
        end
      end
    end
  end
  

  def event(event_type, cmd, idx, payload, raw)
    import introspect
    # next section does beak emulation for yet unknown reason
    # if event_type=='every_50ms'
    #   self.run_deferred()
    # end  #- first run deferred events -#

    # if event_type=='every_250ms'
    #   self.run_cron()
    # end

    var done = false
    var keep_going = false    # if true, we continue dispatch event if done == true (for mqtt_data)

    if event_type == 'mqtt_data'
      keep_going = true
    end

    if event_type=='cmd' return self.exec_cmd(cmd, idx, payload)
    elif event_type=='tele' return self.exec_tele(payload)
    elif event_type=='rule' return self.exec_rules(payload, bool(idx))
    elif event_type=='gc' return self.gc()
    elif self._drivers
      var i = 0
      while i < size(self._drivers)
        var d = self._drivers[i]
        var f = introspect.get(d, event_type)   # try to match a function or method with the same name
        if type(f) == 'function'
          try
            done = f(d, cmd, idx, payload, raw) || done
            if done && !keep_going   break end
          except .. as e,m
            print(format("BRY: Exception> '%s' - %s", e, m))
            if self._debug_present
              import debug
              debug.traceback()
            end
          end
        end
        i += 1
      end
    end

    # save persist
    if event_type=='save_before_restart'
      import persist
      persist.save()
    end

    return done
  end


end

import light_state
import Leds
import Leds_frame

global.tasmota = Tasmota()
return tasmota
