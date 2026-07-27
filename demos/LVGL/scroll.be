# Target resolution: 320x240 (responsive).
# Self-contained port of LVGL's scroll demo.
class ScrollDemo
  var panel, file_list, switches, w

  def switch_cb(obj, event)
    var i = self.switches.find(obj)
    var flags = [lv.OBJ_FLAG_SCROLLABLE, lv.OBJ_FLAG_SCROLL_CHAIN, lv.OBJ_FLAG_SCROLL_ELASTIC, lv.OBJ_FLAG_SCROLL_MOMENTUM]
    if obj.has_state(lv.STATE_CHECKED)
      self.file_list.add_flag(flags[i])
    else
      self.file_list.remove_flag(flags[i])
    end
  end

  def make_switch(title)
    var row = lv.obj(self.panel)
    row.remove_style_all()
    row.set_size(self.w * 55 / 100, 30)
    row.set_flex_flow(lv.FLEX_FLOW_ROW)
    row.set_flex_align(lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_CENTER)
    var text = lv.label(row)
    text.set_text(title)
    text.set_flex_grow(1)
    return lv.switch(row)
  end

  def init()
    lv.start()
    self.w = lv.get_hor_res()
    var h = lv.get_ver_res()
    var scr = lv.scr_act()
    self.panel = lv.obj(scr)
    self.panel.set_size(self.w * 7 / 10, h * 9 / 10)
    self.panel.center()
    self.panel.set_flex_flow(lv.FLEX_FLOW_COLUMN)
    self.panel.set_flex_align(lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_CENTER)
    self.panel.set_style_shadow_width(16, 0)
    self.panel.set_style_shadow_ofs_x(4, 0)
    self.panel.set_style_shadow_ofs_y(8, 0)
    self.panel.set_style_shadow_opa(lv.OPA_40, 0)
    self.panel.set_style_pad_row(6, 0)
    self.file_list = lv.list(self.panel)
    self.file_list.set_width(self.w * 55 / 100)
    self.file_list.set_flex_grow(1)
    var i = 1
    while i <= 10
      self.file_list.add_btn(lv.SYMBOL_IMAGE, f"Image{i}.png")
      i += 1
    end
    self.switches = [self.make_switch("Scrollable"), self.make_switch("Scroll chain"), self.make_switch("Elastic scroll"), self.make_switch("Scroll momentum")]
    var flags = [lv.OBJ_FLAG_SCROLLABLE, lv.OBJ_FLAG_SCROLL_CHAIN, lv.OBJ_FLAG_SCROLL_ELASTIC, lv.OBJ_FLAG_SCROLL_MOMENTUM]
    i = 0
    while i < 4
      self.switches[i].add_state(lv.STATE_CHECKED)
      self.file_list.add_flag(flags[i])
      self.switches[i].add_event_cb(/obj, event -> self.switch_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
      i += 1
    end
    self.file_list.move_foreground()
  end
end

demo = ScrollDemo()
