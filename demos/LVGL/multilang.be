# Target resolution: 470x640.
# Latin transliterations are used because the emulator fonts lack several scripts.
class MultilangDemo
  var en, es, title, subtitle, posts, like_buttons, like_labels, w, h, f14, f20, card_height

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

  def card(y, initials, color)
    var card = lv.obj(lv.scr_act())
    card.set_pos(10, y)
    card.set_size(self.w - 20, self.card_height - 7)
    card.set_style_radius(12, 0)
    card.set_style_border_width(0, 0)
    card.set_style_bg_color(lv.color(0xFFFFFF), 0)
    var avatar = lv.btn(card)
    avatar.set_pos(0, 1)
    avatar.set_size(42, 42)
    avatar.set_style_radius(21, 0)
    avatar.set_style_bg_color(lv.color(color), 0)
    var label = lv.label(avatar)
    label.set_text(initials)
    label.center()
    return card
  end

  def language(obj, event)
    if obj == self.en
      self.title.set_text("WORLD FEED")
      self.subtitle.set_text("People and stories")
      self.posts[0].set_text("Open source and technology enthusiast.")
      self.posts[1].set_text("Coffee, cats, and a first novel in progress.")
      self.posts[2].set_text("Adventure seeker and experienced climber.")
    elif obj == self.es
      self.title.set_text("RED MUNDIAL")
      self.subtitle.set_text("Personas e historias")
      self.posts[0].set_text("Entusiasta del codigo abierto y la tecnologia.")
      self.posts[1].set_text("Cafe, gatos y una primera novela en progreso.")
      self.posts[2].set_text("Aventurera y escaladora con experiencia.")
    else
      self.title.set_text("FIL MONDIAL")
      self.subtitle.set_text("Personnes et histoires")
      self.posts[0].set_text("Passionne par le logiciel libre et la technologie.")
      self.posts[1].set_text("Cafe, chats et un premier roman en cours.")
      self.posts[2].set_text("Aventuriere et alpiniste experimentee.")
    end
  end

  def like(obj, event)
    var i = self.like_buttons.find(obj)
    var counts = [13, 9, 22]
    self.like_labels[i].set_text(lv.SYMBOL_OK + " " + str(counts[i]))
  end

  def language_button(scr, x, caption)
    var button = lv.btn(scr)
    button.set_pos(x, 10)
    button.set_size(38, 38)
    var label = lv.label(button)
    label.set_text(caption)
    label.center()
    return button
  end

  def init()
    lv.start()
    self.w = lv.get_hor_res()
    self.h = lv.get_ver_res()
    self.f14 = lv.montserrat_font(14)
    self.f20 = lv.montserrat_font(20)
    var scr = lv.scr_act()
    scr.set_style_bg_color(lv.color(0xEEF2F7), 0)
    var head = lv.obj(scr)
    head.set_pos(0, 0)
    head.set_size(self.w, 62)
    head.set_style_bg_color(lv.color(0x3567E8), 0)
    head.set_style_bg_opa(lv.OPA_COVER, 0)
    head.set_style_border_width(0, 0)
    self.title = self.text(head, "WORLD FEED", 10, 5, self.f20, 0xFFFFFF)
    self.subtitle = self.text(head, "People and stories", 10, 32, self.f14, 0xDDE7FF)
    self.en = self.language_button(scr, self.w - 132, "EN")
    self.es = self.language_button(scr, self.w - 90, "ES")
    var fr = self.language_button(scr, self.w - 48, "FR")
    self.card_height = (self.h - 82) / 3
    if self.card_height < 76
      self.card_height = 76
    end
    var cards = [self.card(70, "ZW", 0x6D5CE7), self.card(70 + self.card_height, "SB", 0xE76D91), self.card(70 + self.card_height * 2, "AP", 0x28A89A)]
    var names = ["Zhang Wei", "Sofia Bianchi", "Anastasia Petrova"]
    var texts = ["Open source and technology enthusiast.", "Coffee, cats, and a first novel in progress.", "Adventure seeker and experienced climber."]
    var counts = [12, 8, 21]
    self.posts = []
    self.like_buttons = []
    self.like_labels = []
    var i = 0
    while i < 3
      self.text(cards[i], names[i], 52, 0, self.f20, 0x17233B)
      self.posts.push(self.text(cards[i], texts[i], 52, 29, self.f14, 0x53627A))
      var button = lv.btn(cards[i])
      button.set_pos(self.w - 92, self.card_height - 52)
      button.set_size(54, 28)
      var label = lv.label(button)
      label.set_text(lv.SYMBOL_OK + " " + str(counts[i]))
      label.center()
      self.like_buttons.push(button)
      self.like_labels.push(label)
      i += 1
    end
    self.en.add_event_cb(/obj, event -> self.language(obj, event), lv.EVENT_CLICKED, 0)
    self.es.add_event_cb(/obj, event -> self.language(obj, event), lv.EVENT_CLICKED, 0)
    fr.add_event_cb(/obj, event -> self.language(obj, event), lv.EVENT_CLICKED, 0)
    for button : self.like_buttons
      button.add_event_cb(/obj, event -> self.like(obj, event), lv.EVENT_CLICKED, 0)
    end
  end
end

demo = MultilangDemo()
