# Target resolution: 384x384.
# Self-contained Berry interpretation of LVGL's smartwatch demo.
class SmartwatchDemo
  var pages, next_buttons, side, status, play_label, f14, f20, f28
  var white, gray, cyan, pink, green

  def label(parent, value, x, y, font, color)
    var label = lv.label(parent)
    label.set_text(value)
    label.set_pos(x, y)
    if font != nil
      label.set_style_text_font(font, 0)
    end
    label.set_style_text_color(color, 0)
    return label
  end

  def panel(parent, x, y, width, height)
    var panel = lv.obj(parent)
    panel.set_pos(x, y)
    panel.set_size(width, height)
    panel.set_style_radius(18, 0)
    panel.set_style_bg_color(lv.color(0x202630), 0)
    panel.set_style_bg_opa(lv.OPA_COVER, 0)
    panel.set_style_border_width(0, 0)
    panel.set_style_pad_all(9, 0)
    return panel
  end

  def show(index)
    for page : self.pages
      page.set_pos(self.side, 0)
    end
    self.pages[index].set_pos(0, 0)
  end

  def next_page(obj, event)
    var i = self.next_buttons.find(obj)
    self.show((i + 1) % 6)
  end

  def heart_click(obj, event)
    if self.status.get_text() == "Resting heart rate"
      self.status.set_text("Measuring... /\\_/\\_")
    else
      self.status.set_text("Resting heart rate")
    end
    self.status.center()
    self.status.set_pos(0, 31)
  end

  def play_click(obj, event)
    if self.play_label.get_text() == ">"
      self.play_label.set_text("||")
    else
      self.play_label.set_text(">")
    end
    self.play_label.center()
  end

  def next_button(parent, caption)
    var button = lv.btn(parent)
    button.set_size(self.side / 2, 38)
    button.set_pos(self.side / 4, self.side - 53)
    button.set_style_radius(19, 0)
    button.set_style_bg_color(lv.color(0x303744), 0)
    var label = self.label(button, caption, 0, 0, self.f14, self.white)
    label.center()
    self.next_buttons.push(button)
  end

  def add_arc(parent, size, color, value, width)
    var arc = lv.arc(parent)
    arc.set_size(size, size)
    arc.center()
    arc.set_range(0, 100)
    arc.set_value(value)
    arc.set_style_arc_width(width, lv.PART_MAIN)
    arc.set_style_arc_color(lv.color(0x292E36), lv.PART_MAIN)
    arc.set_style_arc_width(width, lv.PART_INDICATOR)
    arc.set_style_arc_color(color, lv.PART_INDICATOR)
    arc.set_style_bg_opa(lv.OPA_TRANSP, lv.PART_KNOB)
  end

  def build_home(page)
    self.add_arc(page, self.side - 24, self.pink, 78, 8)
    self.add_arc(page, self.side - 48, self.cyan, 64, 8)
    self.add_arc(page, self.side - 72, self.green, 88, 8)
    var label = self.label(page, "23:17", 0, 0, self.f28, self.white)
    label.center()
    label.set_pos(0, -18)
    label = self.label(page, "WED  21 JUL", 0, 0, self.f14, self.gray)
    label.center()
    label.set_pos(0, 17)
    label = self.label(page, "24 C  CLEAR", 0, 0, self.f14, self.cyan)
    label.center()
    label.set_pos(0, 42)
    self.next_button(page, "CONTROL")
  end

  def build_control(page)
    var title = self.label(page, "Control center", 0, 0, self.f20, self.white)
    title.center()
    title.set_pos(0, -self.side / 2 + 36)
    var i = 0
    for name : ["Wi-Fi", "Sound", "Lamp", "Focus", "Lock", "Power"]
      var x = self.side / 2 - 112 + (i % 2) * 116
      var y = 55 + (i / 2) * 55
      var panel = self.panel(page, x, y, 106, 45)
      self.label(panel, name, 0, 4, self.f14, self.white)
      var switch = lv.switch(panel)
      switch.set_size(34, 20)
      switch.set_pos(58, 3)
      i += 1
    end
    self.next_button(page, "WEATHER")
  end

  def build_weather(page)
    self.label(page, "BUDAPEST", self.side / 2 - 45, 20, self.f14, self.gray)
    var label = self.label(page, "24 C", 0, 0, self.f28, self.white)
    label.center()
    label.set_pos(0, -self.side / 2 + 66)
    self.label(page, "Clear sky   H:27  L:16", self.side / 2 - 84, 91, self.f14, self.cyan)
    var width = self.side / 3 - 12
    var i = 0
    for value : ["1018 hPa", "UV  3", "54 %"]
      var panel = self.panel(page, 8 + i * (width + 4), 125, width, 55)
      self.label(panel, value, 0, 7, self.f14, self.white)
      i += 1
    end
    self.label(page, "NOW 24   12:00 25   14:00 26", self.side / 2 - 125, 196, self.f14, self.gray)
    self.next_button(page, "HEALTH")
  end

  def build_health(page)
    self.label(page, "HEART", self.side / 2 - 25, 25, self.f14, self.gray)
    var label = self.label(page, "64", 0, 0, self.f28, self.pink)
    label.center()
    label.set_pos(0, -30)
    label = self.label(page, "BPM", 0, 0, self.f14, self.white)
    label.center()
    label.set_pos(0, 2)
    self.status = self.label(page, "Resting heart rate", 0, 0, self.f14, self.gray)
    self.status.center()
    self.status.set_pos(0, 31)
    var button = lv.btn(page)
    button.set_pos(self.side / 2 - 70, self.side - 102)
    button.set_size(140, 38)
    label = self.label(button, "START / STOP", 0, 0, self.f14, self.white)
    label.center()
    button.add_event_cb(/obj, event -> self.heart_click(obj, event), lv.EVENT_CLICKED, 0)
    self.next_button(page, "SPORTS")
  end

  def build_sports(page)
    self.label(page, "TODAY'S ACTIVITY", self.side / 2 - 68, 21, self.f14, self.white)
    self.add_arc(page, self.side - 45, self.pink, 82, 9)
    self.add_arc(page, self.side - 80, self.cyan, 67, 9)
    self.add_arc(page, self.side - 115, self.green, 54, 9)
    var label = self.label(page, "8,426 STEPS   6.3 KM   472 KCAL", 0, 0, self.f14, self.white)
    label.center()
    label.set_pos(0, 51)
    self.next_button(page, "MUSIC")
  end

  def build_music(page)
    self.label(page, "NOW PLAYING", self.side / 2 - 50, 24, self.f14, self.gray)
    var album = self.panel(page, self.side / 2 - 58, 55, 116, 100)
    album.set_style_bg_color(lv.color(0x633B78), 0)
    var label = self.label(album, "NEON\nNIGHTS", 0, 0, self.f20, self.white)
    label.center()
    label = self.label(page, "Midnight Drive", 0, 0, self.f20, self.white)
    label.center()
    label.set_pos(0, 42)
    label = self.label(page, "The Satellites", 0, 0, self.f14, self.gray)
    label.center()
    label.set_pos(0, 66)
    var play = lv.btn(page)
    play.set_size(54, 54)
    play.set_pos(self.side / 2 - 27, self.side - 111)
    play.set_style_radius(27, 0)
    self.play_label = self.label(play, ">", 0, 0, self.f20, self.white)
    self.play_label.center()
    play.add_event_cb(/obj, event -> self.play_click(obj, event), lv.EVENT_CLICKED, 0)
    self.next_button(page, "WATCH FACE")
  end

  def init()
    lv.start()
    var w = lv.get_hor_res()
    var h = lv.get_ver_res()
    self.side = w
    if h < self.side
      self.side = h
    end
    self.f14 = lv.montserrat_font(14)
    self.f20 = lv.montserrat_font(20)
    self.f28 = lv.montserrat_font(28)
    self.white = lv.color(0xFFFFFF)
    self.gray = lv.color(0x92979E)
    self.cyan = lv.color(0x38D8FF)
    self.pink = lv.color(0xFF4778)
    self.green = lv.color(0x81E65B)
    var scr = lv.scr_act()
    scr.set_style_bg_color(lv.color(0x080A0D), 0)
    scr.set_style_bg_opa(lv.OPA_COVER, 0)
    var face = lv.obj(scr)
    face.set_size(self.side, self.side)
    face.set_pos((w - self.side) / 2, (h - self.side) / 2)
    face.set_style_radius(self.side / 2, 0)
    face.set_style_bg_color(lv.color(0x11151B), 0)
    face.set_style_bg_opa(lv.OPA_COVER, 0)
    face.set_style_border_width(0, 0)
    face.set_style_pad_all(0, 0)
    self.pages = []
    self.next_buttons = []
    var i = 0
    while i < 6
      var page = lv.obj(face)
      page.set_size(self.side, self.side)
      page.set_pos(self.side, 0)
      page.set_style_bg_opa(lv.OPA_TRANSP, 0)
      page.set_style_border_width(0, 0)
      page.set_style_pad_all(0, 0)
      self.pages.push(page)
      i += 1
    end
    self.build_home(self.pages[0])
    self.build_control(self.pages[1])
    self.build_weather(self.pages[2])
    self.build_health(self.pages[3])
    self.build_sports(self.pages[4])
    self.build_music(self.pages[5])
    for button : self.next_buttons
      button.add_event_cb(/obj, event -> self.next_page(obj, event), lv.EVENT_CLICKED, 0)
    end
    self.show(0)
  end
end

demo = SmartwatchDemo()
