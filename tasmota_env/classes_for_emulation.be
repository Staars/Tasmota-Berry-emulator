#- Native code used for testing and code solidification -#
#- Do not use it -#

#@ solidify:Driver
class Driver
  var every_second
  var every_100ms
  var web_add_handler
  var web_add_button
  var web_add_main_button
  var web_add_management_button
  var web_add_config_button
  var web_add_console_button
  var save_before_restart
  var web_sensor
  var json_append
  var after_teleperiod
  var button_pressed
  var display

  def add_cmd(c, f)
    import string
    if type(f) != 'function'
      raise "value_error", "function required"
    end
    if type(c) == 'string' && string.startswith(c, "/")
      # wildcard command prefix - not supported by the emulator dispatcher
      return
    end
    tasmota.add_cmd(c, / cmd, idx, payload, payload_json -> f(self, cmd, idx, payload, payload_json))
  end
end