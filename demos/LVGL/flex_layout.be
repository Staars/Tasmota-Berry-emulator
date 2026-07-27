# Target resolution: 320x240 (responsive).
# Compact, responsive port of LVGL's interactive flex-layout editor.
class FlexLayoutDemo
  var play, add_btn, w, h

  def add_node()
    var n = self.play.get_child_count()
    var node = lv.obj(self.play)
    node.set_size(self.w * 11 / 100, self.h * 18 / 100)
    node.set_style_radius(2, 0)
    node.set_style_bg_color(lv.color(0x90caf9), 0)
    var label = lv.label(node)
    label.set_text(str(n))
    label.center()
  end

  def flow_cb(obj, event)
    var flows = [lv.FLEX_FLOW_ROW, lv.FLEX_FLOW_COLUMN, lv.FLEX_FLOW_ROW_WRAP, lv.FLEX_FLOW_ROW_REVERSE, lv.FLEX_FLOW_COLUMN_REVERSE]
    self.play.set_flex_flow(flows[obj.get_selected()])
  end

  def align_cb(obj, event)
    var aligns = [lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_SPACE_AROUND, lv.FLEX_ALIGN_SPACE_BETWEEN, lv.FLEX_ALIGN_SPACE_EVENLY]
    self.play.set_flex_align(aligns[obj.get_selected()], lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_START)
  end

  def scroll_cb(obj, event)
    if obj.has_state(lv.STATE_CHECKED)
      self.play.add_flag(lv.OBJ_FLAG_SCROLLABLE)
    else
      self.play.remove_flag(lv.OBJ_FLAG_SCROLLABLE)
    end
  end

  def button_cb(obj, event)
    if obj == self.add_btn
      self.add_node()
    elif self.play.get_child_count() > 0
      self.play.get_child(-1).delete()
    end
  end

  def init()
    lv.start()
    self.w = lv.get_hor_res()
    self.h = lv.get_ver_res()
    var scr = lv.scr_act()
    scr.set_flex_flow(lv.FLEX_FLOW_ROW)
    scr.set_flex_align(lv.FLEX_ALIGN_SPACE_AROUND, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_CENTER)
    self.play = lv.obj(scr)
    self.play.set_size(self.w * 53 / 100, self.h * 82 / 100)
    self.play.set_flex_flow(lv.FLEX_FLOW_ROW_WRAP)
    self.play.set_flex_align(lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_START)
    self.play.set_style_pad_all(5, 0)
    self.play.set_style_pad_gap(5, 0)
    var controls = lv.obj(scr)
    controls.set_size(self.w * 40 / 100, self.h * 82 / 100)
    controls.set_flex_flow(lv.FLEX_FLOW_COLUMN)
    controls.set_flex_align(lv.FLEX_ALIGN_START, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_CENTER)
    controls.set_style_pad_all(6, 0)
    controls.set_style_pad_row(5, 0)
    var title = lv.label(controls)
    title.set_text("Flex layout")
    var flow_dd = lv.dropdown(controls)
    flow_dd.set_width(self.w * 34 / 100)
    flow_dd.set_options("Row\nColumn\nRow wrap\nRow reverse\nColumn reverse")
    var align_dd = lv.dropdown(controls)
    align_dd.set_width(self.w * 34 / 100)
    align_dd.set_options("Start\nCenter\nSpace around\nSpace between\nSpace evenly")
    var scroll = lv.checkbox(controls)
    scroll.set_text("Scrollable")
    scroll.add_state(lv.STATE_CHECKED)
    var buttons = lv.obj(controls)
    buttons.remove_style_all()
    buttons.set_size(self.w * 34 / 100, 34)
    buttons.set_flex_flow(lv.FLEX_FLOW_ROW)
    buttons.set_flex_align(lv.FLEX_ALIGN_SPACE_AROUND, lv.FLEX_ALIGN_CENTER, lv.FLEX_ALIGN_CENTER)
    self.add_btn = lv.btn(buttons)
    self.add_btn.set_size(self.w * 14 / 100, 30)
    var label = lv.label(self.add_btn)
    label.set_text("Add")
    label.center()
    var remove_btn = lv.btn(buttons)
    remove_btn.set_size(self.w * 14 / 100, 30)
    remove_btn.set_style_bg_color(lv.color(0xd94b4b), 0)
    label = lv.label(remove_btn)
    label.set_text("Remove")
    label.center()
    flow_dd.add_event_cb(/obj, event -> self.flow_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
    align_dd.add_event_cb(/obj, event -> self.align_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
    scroll.add_event_cb(/obj, event -> self.scroll_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
    self.add_btn.add_event_cb(/obj, event -> self.button_cb(obj, event), lv.EVENT_CLICKED, 0)
    remove_btn.add_event_cb(/obj, event -> self.button_cb(obj, event), lv.EVENT_CLICKED, 0)
    var i = 0
    while i < 8
      self.add_node()
      i += 1
    end
  end
end

demo = FlexLayoutDemo()
