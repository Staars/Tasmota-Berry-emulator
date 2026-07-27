# Target resolution: 320x240.
# A simple Tasmota screen.
class SimpleDemo
  var prev_btn, next_btn, home_btn, btn_style, wifi_icon, clock_icon

  def clicked_cb(obj, event)
    var btn = "Unknown"
    if obj == self.prev_btn
      btn = "Prev"
    elif obj == self.next_btn
      btn = "Next"
    elif obj == self.home_btn
      btn = "Home"
    end
    var indev = event.get_indev()
    var point = lv.point()
    indev.get_point(point)
    var area = lv.area()
    obj.get_coords(area)
    print(f"{btn} button pressed at ({point.x},{point.y}) local ({point.x - area.x1},{point.y - area.y1})")
  end

  def make_button(scr, x, text)
    var button = lv.btn(scr)
    button.set_pos(x, lv.get_ver_res() - 40)
    button.set_size(80, 35)
    button.add_style(self.btn_style, lv.PART_MAIN | lv.STATE_DEFAULT)
    var label = lv.label(button)
    label.set_text(text)
    label.center()
    return button
  end

  def init()
    lv.start()
    var hres = lv.get_hor_res()
    var scr = lv.scr_act()
    var f20 = lv.montserrat_font(20)
    scr.set_style_bg_color(lv.color(0x000077), lv.PART_MAIN | lv.STATE_DEFAULT)
    var stat_line = lv.label(scr)
    if f20 != nil
      stat_line.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT)
    end
    stat_line.set_long_mode(lv.LABEL_LONG_SCROLL)
    stat_line.set_width(hres)
    stat_line.set_align(lv.TEXT_ALIGN_LEFT)
    stat_line.set_style_bg_color(lv.color(0xD00000), lv.PART_MAIN | lv.STATE_DEFAULT)
    stat_line.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
    stat_line.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)
    stat_line.set_text("Tasmota")
    stat_line.refr_size()
    stat_line.refr_pos()
    self.wifi_icon = lv_wifi_arcs_icon(stat_line)
    self.clock_icon = lv_clock_icon(stat_line)
    self.btn_style = lv.style()
    self.btn_style.set_radius(10)
    self.btn_style.set_bg_opa(lv.OPA_COVER)
    if f20 != nil
      self.btn_style.set_text_font(f20)
    end
    self.btn_style.set_bg_color(lv.color(0x1fa3ec))
    self.btn_style.set_border_color(lv.color(0x0000FF))
    self.btn_style.set_text_color(lv.color(0xFFFFFF))
    self.prev_btn = self.make_button(scr, 20, "<")
    self.next_btn = self.make_button(scr, 220, ">")
    self.home_btn = self.make_button(scr, 120, lv.SYMBOL_OK)
    self.prev_btn.add_event_cb(/obj, event -> self.clicked_cb(obj, event), lv.EVENT_CLICKED, 0)
    self.next_btn.add_event_cb(/obj, event -> self.clicked_cb(obj, event), lv.EVENT_CLICKED, 0)
    self.home_btn.add_event_cb(/obj, event -> self.clicked_cb(obj, event), lv.EVENT_CLICKED, 0)
  end
end

demo = SimpleDemo()
