# Target resolution: 400x400.
# Self-contained port of LVGL's transform demo (the avatar is drawn with widgets).
class TransformDemo
  var scr, w, h, transform_card

  def make_card(opa)
    var card = lv.obj(self.scr)
    var cw = self.w * 3 / 4
    if cw > 300
      cw = 300
    end
    var ch = self.h * 3 / 10
    if ch < 82
      ch = 82
    end
    if ch > 120
      ch = 120
    end
    card.set_size(cw, ch)
    card.center()
    card.remove_flag(lv.OBJ_FLAG_SCROLLABLE | lv.OBJ_FLAG_CLICKABLE)
    card.set_style_radius(12, 0)
    card.set_style_border_width(0, 0)
    card.set_style_shadow_width(16, 0)
    card.set_style_shadow_ofs_y(5, 0)
    card.set_style_opa(opa, 0)
    var avatar = lv.obj(card)
    var av = ch * 55 / 100
    avatar.set_size(av, av)
    avatar.align(lv.ALIGN_LEFT_MID, 8, 0)
    avatar.set_style_radius(lv.RADIUS_CIRCLE, 0)
    avatar.set_style_bg_color(lv.color(0x759efe), 0)
    avatar.set_style_border_width(0, 0)
    var face = lv.label(avatar)
    face.set_text(lv.SYMBOL_HOME)
    face.center()
    var name = lv.label(card)
    name.set_text("Pavel Svoboda")
    name.align(lv.ALIGN_TOP_LEFT, av + 18, 8)
    var like = lv.btn(card)
    like.set_size((cw - av - 34) * 3 / 4, 34)
    like.align(lv.ALIGN_BOTTOM_LEFT, av + 18, -7)
    like.set_style_radius(lv.RADIUS_CIRCLE, 0)
    like.set_style_bg_color(lv.color(0x4173ff), 0)
    var label = lv.label(like)
    label.set_text(lv.SYMBOL_OK + "  Like")
    label.center()
    return card
  end

  def arc_cb(obj, event)
    self.transform_card.set_style_transform_rotation(obj.get_value() * 10, 0)
  end

  def slider_cb(obj, event)
    var v = obj.get_value()
    self.transform_card.set_style_transform_scale_x(v, 0)
    self.transform_card.set_style_transform_scale_y(v, 0)
  end

  def init()
    lv.start()
    self.scr = lv.scr_act()
    self.w = lv.get_hor_res()
    self.h = lv.get_ver_res()
    var short_side = self.w
    if self.h < short_side
      short_side = self.h
    end
    var ghost = self.make_card(lv.OPA_50)
    self.transform_card = self.make_card(lv.OPA_COVER)
    var arc = lv.arc(self.scr)
    var arc_size = short_side - 20
    arc.set_size(arc_size, arc_size)
    arc.set_range(0, 270)
    arc.set_value(225)
    arc.center()
    arc.add_flag(lv.OBJ_FLAG_ADV_HITTEST)
    arc.add_event_cb(/obj, event -> self.arc_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
    ghost.move_foreground()
    self.transform_card.move_foreground()
    var slider = lv.slider(self.scr)
    slider.set_width(self.w * 7 / 10)
    slider.align(lv.ALIGN_BOTTOM_MID, 0, -12)
    slider.set_range(128, 300)
    slider.set_value(256, lv.ANIM_OFF)
    slider.add_event_cb(/obj, event -> self.slider_cb(obj, event), lv.EVENT_VALUE_CHANGED, 0)
  end
end

demo = TransformDemo()
