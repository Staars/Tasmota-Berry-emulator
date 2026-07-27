# Target resolution: 480x320.
# Self-contained Berry interpretation of LVGL's e-bike demo.
class EbikeDemo
  var w, h, body_h, pages, buttons, f14, f20, f28, ink, muted, lime, panel

  def text(parent, value, x, y, font, color)
    var label = lv.label(parent)
    label.set_text(value)
    label.set_pos(x, y)
    if font != nil
      label.set_style_text_font(font, 0)
    end
    label.set_style_text_color(color, 0)
    return label
  end

  def box(parent, x, y, width, height)
    var box = lv.obj(parent)
    box.set_pos(x, y)
    box.set_size(width, height)
    box.set_style_radius(16, 0)
    box.set_style_bg_color(self.panel, 0)
    box.set_style_bg_opa(lv.OPA_COVER, 0)
    box.set_style_border_width(0, 0)
    box.set_style_pad_all(10, 0)
    return box
  end

  def show_page(index)
    for page : self.pages
      page.set_pos(self.w, 0)
    end
    self.pages[index].set_pos(0, 0)
  end

  def nav_click(obj, event)
    self.show_page(self.buttons.find(obj))
  end

  def build_home(home)
    self.text(home, "09:41", 12, 8, self.f14, self.muted)
    self.text(home, "E-BIKE", self.w - 70, 8, self.f14, self.lime)
    var arc_size = self.body_h - 62
    if arc_size > self.w - 28
      arc_size = self.w - 28
    end
    if arc_size < 125
      arc_size = 125
    end
    var speed = lv.arc(home)
    speed.set_size(arc_size, arc_size)
    speed.set_pos((self.w - arc_size) / 2, 27)
    speed.set_range(0, 60)
    speed.set_value(24)
    speed.set_bg_angles(135, 405)
    speed.set_style_arc_width(13, lv.PART_MAIN)
    speed.set_style_arc_color(lv.color(0x303936), lv.PART_MAIN)
    speed.set_style_arc_width(13, lv.PART_INDICATOR)
    speed.set_style_arc_color(self.lime, lv.PART_INDICATOR)
    speed.set_style_bg_opa(lv.OPA_TRANSP, lv.PART_KNOB)
    var value = self.text(home, "24", 0, 0, self.f28, self.ink)
    value.center()
    value.set_pos(0, -9)
    var unit = self.text(home, "km/h", 0, 0, self.f14, self.muted)
    unit.center()
    unit.set_pos(0, 21)
    var card_width = (self.w - 36) / 2
    var card = self.box(home, 12, self.body_h - 68, card_width, 57)
    self.text(card, "BATTERY", 0, 0, self.f14, self.muted)
    self.text(card, "82%", 0, 22, self.f20, self.ink)
    card = self.box(home, 24 + card_width, self.body_h - 68, card_width, 57)
    self.text(card, "RANGE", 0, 0, self.f14, self.muted)
    self.text(card, "48 km", 0, 22, self.f20, self.ink)
  end

  def build_settings(page)
    self.text(page, "Settings", 14, 10, self.f28, self.ink)
    self.text(page, "Bike preferences", 16, 43, self.f14, self.muted)
    var y = 72
    for name : ["Bluetooth", "Head lamp"]
      var row = self.box(page, 12, y, self.w - 24, 43)
      self.text(row, name, 2, 2, self.f14, self.ink)
      var switch = lv.switch(row)
      switch.set_size(45, 24)
      switch.set_pos(self.w - 93, 0)
      y += 49
    end
    for name : ["Brightness", "Volume", "Max speed"]
      var row = self.box(page, 12, y, self.w - 24, 48)
      self.text(row, name, 2, 0, self.f14, self.ink)
      var slider = lv.slider(row)
      slider.set_pos(self.w / 2 - 25, 5)
      slider.set_size(self.w / 2 - 50, 12)
      slider.set_range(0, 100)
      slider.set_value(70, lv.ANIM_OFF)
      y += 54
    end
  end

  def build_stats(page)
    self.text(page, "Ride statistics", 14, 10, self.f28, self.ink)
    self.text(page, "<   JUL 15 - JUL 21   >", 16, 47, self.f14, self.muted)
    var chart_height = self.body_h - 142
    if chart_height < 45
      chart_height = 45
    end
    var chart = self.box(page, 12, 73, self.w - 24, chart_height)
    self.text(chart, "DISTANCE   TIME   ENERGY", 2, 0, self.f14, self.lime)
    var bar_width = (self.w - 62) / 7
    var i = 0
    for value : [35, 68, 48, 82, 57, 94, 63]
      var bar_height = value * (chart_height - 30) / 100
      var bar = lv.obj(chart)
      bar.set_size(bar_width - 4, bar_height)
      bar.set_pos(4 + i * bar_width, chart_height - 20 - bar_height)
      bar.set_style_bg_color(self.lime, 0)
      bar.set_style_bg_opa(lv.OPA_COVER, 0)
      bar.set_style_border_width(0, 0)
      bar.set_style_radius(4, 0)
      i += 1
    end
    var summary = self.box(page, 12, self.body_h - 61, self.w - 24, 50)
    self.text(summary, "THIS WEEK", 2, 0, self.f14, self.muted)
    self.text(summary, "126 km     5h 42m     2,480 kcal", 2, 22, self.f14, self.ink)
  end

  def init()
    lv.start()
    self.w = lv.get_hor_res()
    self.h = lv.get_ver_res()
    self.body_h = self.h - 52
    self.f14 = lv.montserrat_font(14)
    self.f20 = lv.montserrat_font(20)
    self.f28 = lv.montserrat_font(28)
    self.ink = lv.color(0xF4F7F2)
    self.muted = lv.color(0x87918B)
    self.lime = lv.color(0xC9F449)
    self.panel = lv.color(0x222A27)
    var scr = lv.scr_act()
    scr.set_style_bg_color(lv.color(0x101417), 0)
    scr.set_style_bg_opa(lv.OPA_COVER, 0)
    self.pages = []
    var i = 0
    while i < 3
      var page = lv.obj(scr)
      page.set_size(self.w, self.body_h)
      page.set_pos(self.w, 0)
      page.set_style_bg_color(lv.color(0x101417), 0)
      page.set_style_bg_opa(lv.OPA_COVER, 0)
      page.set_style_border_width(0, 0)
      page.set_style_pad_all(0, 0)
      self.pages.push(page)
      i += 1
    end
    self.build_home(self.pages[0])
    self.build_settings(self.pages[1])
    self.build_stats(self.pages[2])
    var nav = lv.obj(scr)
    nav.set_pos(0, self.h - 52)
    nav.set_size(self.w, 52)
    nav.set_style_bg_color(lv.color(0x1A201E), 0)
    nav.set_style_bg_opa(lv.OPA_COVER, 0)
    nav.set_style_border_width(0, 0)
    nav.set_style_pad_all(4, 0)
    self.buttons = []
    i = 0
    for name : ["HOME", "SETTINGS", "STATS"]
      var button = lv.btn(nav)
      button.set_pos(i * self.w / 3 + 3, 2)
      button.set_size(self.w / 3 - 6, 40)
      button.set_style_bg_color(self.panel, 0)
      button.set_style_radius(12, 0)
      var label = self.text(button, name, 0, 0, self.f14, self.ink)
      label.center()
      self.buttons.push(button)
      i += 1
    end
    for button : self.buttons
      button.add_event_cb(self.nav_click, lv.EVENT_CLICKED, 0)
    end
    self.show_page(0)
  end
end

demo = EbikeDemo()
