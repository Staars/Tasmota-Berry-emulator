# Target resolutions: 800x480, 1280x720, or 1920x1080.
# Native panels and controls replace upstream image assets.
class HighResDemo
  var nav, status, t1, v1, t2, v2, climate, scene_label, v3, v4, s4
  var f14, f20, f28

  def text(parent, value, x, y, font, color)
    var label = lv.label(parent)
    label.set_text(value)
    label.set_pos(x, y)
    if font != nil
      label.set_style_text_font(font, 0)
    end
    label.set_style_text_color(lv.color(color), 0)
    return label
  end

  def pane(parent, x, y, width, height)
    var pane = lv.obj(parent)
    pane.set_pos(x, y)
    pane.set_size(width, height)
    pane.set_style_radius(14, 0)
    pane.set_style_border_width(1, 0)
    pane.set_style_border_color(lv.color(0x263750), 0)
    pane.set_style_bg_color(lv.color(0x122139), 0)
    pane.set_style_bg_opa(lv.OPA_COVER, 0)
    pane.set_style_pad_all(10, 0)
    return pane
  end

  def nav_cb(obj, event)
    var i = self.nav.find(obj)
    if i == 0
      self.status.set_text("Home overview  |  All systems normal")
      self.t1.set_text("HOME ENERGY")
      self.v1.set_text("3.8 kW")
      self.t2.set_text("CLIMATE")
    elif i == 1
      self.status.set_text("Energy  |  Live power flow")
      self.t1.set_text("SOLAR OUTPUT")
      self.v1.set_text("2.6 kW")
      self.t2.set_text("TODAY")
      self.v2.set_text("18.4 kWh")
    elif i == 2
      self.status.set_text("Climate  |  Three active zones")
      self.t1.set_text("AIR QUALITY")
      self.v1.set_text("Excellent")
      self.t2.set_text("SET POINT")
      self.v2.set_text(str(self.climate.get_value()) + " C")
    else
      self.status.set_text("About  |  Native Berry high-res adaptation")
      self.t1.set_text("LVGL")
      self.v1.set_text("Master demo")
      self.t2.set_text("ASSETS")
      self.v2.set_text("Native UI")
    end
  end

  def climate_cb(obj, event)
    self.v2.set_text(str(obj.get_value()) + " C")
  end

  def scene_cb(obj, event)
    self.scene_label.set_text("Evening active")
    self.v3.set_text("9 devices")
  end

  def charge_cb(obj, event)
    if obj.has_state(lv.STATE_CHECKED)
      self.v4.set_text("Charging now")
      self.s4.set_text("6.4 kW  |  184 km range")
    else
      self.v4.set_text("184 km range")
      self.s4.set_text("Paused  |  Tap switch")
    end
  end

  def init()
    lv.start()
    var w = lv.get_hor_res()
    var h = lv.get_ver_res()
    var scr = lv.scr_act()
    scr.set_style_bg_color(lv.color(0x09111F), 0)
    self.f14 = lv.montserrat_font(14)
    self.f20 = lv.montserrat_font(20)
    self.f28 = lv.montserrat_font(28)
    var margin = 10
    var rail = 62
    if w < 600
      rail = 46
    end
    var top = 58
    var gap = 10
    var usable = w - rail - margin * 2
    var column = (usable - gap * 2) / 3
    if w < 600
      column = (usable - gap) / 2
    end
    var row = (h - top - margin * 2 - gap) / 2
    self.text(scr, "LVGL  CONTROL CENTER", margin, 10, self.f20, 0xFFFFFF)
    self.status = self.text(scr, "Connected  |  21 C outside", rail + margin, 38, self.f14, 0x8FA8C8)
    self.text(scr, "09:41", w - 70, 12, self.f20, 0x65D7FF)
    self.nav = []
    var symbols = [lv.SYMBOL_HOME, lv.SYMBOL_CHARGE, lv.SYMBOL_REFRESH, lv.SYMBOL_SETTINGS]
    var i = 0
    while i < 4
      var button = lv.btn(scr)
      button.set_pos(margin, top + i * 50)
      button.set_size(rail - 10, 42)
      var label = lv.label(button)
      label.set_text(symbols[i])
      label.center()
      self.nav.push(button)
      i += 1
    end
    var x = rail + margin
    var p1 = self.pane(scr, x, top, column, row)
    var p2 = self.pane(scr, x + column + gap, top, column, row)
    var p3x = x
    var p3y = top + row + gap
    if w >= 600
      p3x = x + (column + gap) * 2
      p3y = top
    end
    var p3 = self.pane(scr, p3x, p3y, column, row)
    var p4x = x + column + gap
    var p4w = column
    if w >= 600
      p4x = x
      p4w = usable
    end
    var p4 = self.pane(scr, p4x, top + row + gap, p4w, row)
    self.t1 = self.text(p1, "HOME ENERGY", 0, 0, self.f14, 0x8FA8C8)
    self.v1 = self.text(p1, "3.8 kW", 0, 27, self.f28, 0x65D7FF)
    self.text(p1, "Solar 2.6  Grid 1.2", 0, 64, self.f14, 0xB8C9DF)
    var meter = lv.bar(p1)
    meter.set_pos(0, row - 42)
    meter.set_size(column - 22, 12)
    meter.set_range(0, 100)
    meter.set_value(68, 0)
    self.t2 = self.text(p2, "CLIMATE", 0, 0, self.f14, 0x8FA8C8)
    self.v2 = self.text(p2, "22 C", 0, 27, self.f28, 0xFFB86B)
    self.text(p2, "Living room  |  Auto", 0, 64, self.f14, 0xB8C9DF)
    self.climate = lv.slider(p2)
    self.climate.set_pos(0, row - 46)
    self.climate.set_size(column - 22, 14)
    self.climate.set_range(16, 30)
    self.climate.set_value(22, 0)
    self.text(p3, "SMART HOME", 0, 0, self.f14, 0x8FA8C8)
    self.v3 = self.text(p3, "8 devices", 0, 30, self.f20, 0xA6F3C5)
    self.text(p3, "Lights and scenes", 0, 61, self.f14, 0xB8C9DF)
    var scene = lv.btn(p3)
    scene.set_pos(0, row - 52)
    scene.set_size(column - 22, 34)
    self.scene_label = lv.label(scene)
    self.scene_label.set_text("Activate evening")
    self.scene_label.center()
    self.text(p4, "EV CHARGING", 0, 0, self.f14, 0x8FA8C8)
    self.v4 = self.text(p4, "184 km range", 0, 28, self.f20, 0x65D7FF)
    self.s4 = self.text(p4, "6.4 kW  |  Ready 11:20", 0, 57, self.f14, 0xB8C9DF)
    var charge = lv.switch(p4)
    charge.set_pos(p4w - 62, 24)
    charge.set_size(48, 26)
    self.text(p4, "Navigation, slider, scene and charging are interactive", 0, row - 34, self.f14, 0x7188A8)
    for button : self.nav
      button.add_event_cb(self.nav_cb, lv.EVENT_CLICKED, 0)
    end
    self.climate.add_event_cb(self.climate_cb, lv.EVENT_VALUE_CHANGED, 0)
    scene.add_event_cb(self.scene_cb, lv.EVENT_CLICKED, 0)
    charge.add_event_cb(self.charge_cb, lv.EVENT_VALUE_CHANGED, 0)
  end
end

demo = HighResDemo()
