# Leds


class Leds
  static var WS2812_GRB = 1
  static var SK6812_GRBW = 2

  var gamma       # if true, apply gamma (true is default)
  var leds        # number of leds
  var bri         # implicit brightness for this led strip (0..255, default is 50% = 127)

  var _buf
  var _typ
  # leds:int = number of leds of the strip
  # gpio:int (optional) = GPIO for NeoPixel. If not specified, takes the WS2812 gpio
  # typ:int (optional) = Type of LED, defaults to WS2812 RGB
  # rmt:int (optional) = RMT hardware channel to use, leave default unless you have a good reason 
  def init(leds, gpio_phy, typ, rmt)   # rmt is optional
    self.gamma = true     # gamma is enabled by default, it should be disabled explicitly if needed
    self.leds = int(leds)
    self.bri = 127

    # fake buffer
    self._buf = bytes(leds).resize(leds * 3)
    self._typ = typ
    # if no GPIO, abort
    # if gpio_phy == nil
    #   raise "valuer_error", "no GPIO specified for neopixelbus"
    # end

    # initialize the structure
    self.ctor(self.leds, gpio_phy, typ, rmt)

    # if self._p == nil raise "internal_error", "couldn't not initialize noepixelbus" end

    # call begin
    self.begin()

    # emulator-specific
    global._strip = self    # record the current strip object

  end

  # set bri (0..255)
  def set_bri(bri)
    if (bri < 0)    bri = 0   end
    if (bri > 255)  bri = 255 end
    self.bri = bri
  end
  def get_bri()
    return self.bri
  end

  def set_gamma(gamma)
    self.gamma = bool(gamma)
  end
  def get_gamma()
    return self.gamma
  end

  # assign RMT
  static def assign_rmt(gpio_phy)
  end

  def clear()
    self.clear_to(0x000000)
    self.show()
  end

  def ctor(leds, gpio_phy, typ, rmt)
    if typ == nil
      typ = self.WS2812_GRB
    end
    self._typ = typ
    # if rmt == nil
    #   rmt = self.assign_rmt(gpio_phy)
    # end
    # self.call_native(0, leds, gpio_phy, typ, rmt)
  end
  def begin()
  end
  def show()
    tasmota.led_buffer(f'{self._buf.tohex()}')
  end
  def can_show()
    return true
  end
  def is_dirty()
    return true
  end
  def dirty()
  end
  def pixels_buffer(old_buf)
    return self._buf
  end
  def pixel_size()
    return size(self._buf)/self.leds
    # return self.call_native(7)
  end
  def pixel_count()
    return self.leds
    # return self.call_native(8)
  end
  def pixel_offset()
    return 0
  end
  def clear_to(col, bri)
    if (bri == nil)   bri = self.bri    end
    var rgb = self.to_gamma(col, bri)
    var buf = self._buf
    var r = (rgb >> 16) & 0xFF
    var g = (rgb >>  8) & 0xFF
    var b = (rgb      ) & 0xFF
    var i = 0
    while i < self.leds
      buf[i * 3 + 0] = r
      buf[i * 3 + 1] = g
      buf[i * 3 + 2] = b
      i += 1
    end
  end
  def set_pixel_color(idx, col, bri)
    if (bri == nil)   bri = self.bri    end
    var rgb = self.to_gamma(col, bri)
    var buf = self._buf
    var r = (rgb >> 16) & 0xFF
    var g = (rgb >>  8) & 0xFF
    var b = (rgb      ) & 0xFF

    buf[idx * 3 + 0] = r
    buf[idx * 3 + 1] = g
    buf[idx * 3 + 2] = b
    # self.call_native(10, idx, self.to_gamma(col, bri))
  end
  def get_pixel_color(idx)
    var buf = self._buf
    return buf[idx * 3 + 0] << 16 | buf[idx * 3 + 1] << 8 | buf[idx * 3 + 2]
    #return self.call_native(11, idx)
  end

  # apply gamma and bri
  def to_gamma(rgb, bri255)
    if (bri255 == nil)   bri255 = self.bri    end
    return self.apply_bri_gamma(rgb, bri255, self.gamma)
  end

  # `segment`
  # create a new `strip` object that maps a part of the current strip
  def create_segment(offset, leds)
    if int(offset) + int(leds) > self.leds || offset < 0 || leds < 0
      raise "value_error", "out of range"
    end

    # inner class
    class Leds_segment
      var strip
      var offset, leds
    
      def init(strip, offset, leds)
        self.strip = strip
        self.offset = int(offset)
        self.leds = int(leds)
      end
    
      def clear()
        self.clear_to(0x000000)
        self.show()
      end
    
      def begin()
        # do nothing, already being handled by physical strip
      end
      def show(force)
        # don't trigger on segment, you will need to trigger on full strip instead
        if bool(force) || (self.offset == 0 && self.leds == self.strip.leds)
          self.strip.show()
        end
      end
      def can_show()
        return self.strip.can_show()
      end
      def is_dirty()
        return self.strip.is_dirty()
      end
      def dirty()
        self.strip.dirty()
      end
      def pixels_buffer()
        return nil
      end
      def pixel_size()
        return self.strip.pixel_size()
      end
      def pixel_offset()
        return self.offset
      end
      def pixel_count()
        return self.leds
      end
      def clear_to(col, bri)
        if (bri == nil)   bri = self.bri    end
        # self.strip.call_native(9, self.strip.to_gamma(col, bri), self.offset, self.leds)
        self.strip.clear_to(col, bri)
        # var i = 0
        # while i < self.leds
        #   self.strip.set_pixel_color(i + self.offset, col, bri)
        #   i += 1
        # end
      end
      def set_pixel_color(idx, col, bri)
        if (bri == nil)   bri = self.bri    end
        self.strip.set_pixel_color(idx + self.offset, col, bri)
      end
      def get_pixel_color(idx)
        return self.strip.get_pixel_color(idx + self.offseta)
      end
    end

    return Leds_segment(self, offset, leds)

  end


  static def blend_color(color_a, color_b, alpha)
    var transparency = (color_b >> 24) & 0xFF
    if (alpha != nil)
      transparency = 255 - alpha
    end
    # remove any transparency
    color_a = color_a & 0xFFFFFF
    color_b = color_b & 0xFFFFFF

    if (transparency == 0) #     // color_b is opaque, return color_b
      return color_b
    end
    if (transparency >= 255) #{  // color_b is transparent, return color_a
      return color_a
    end
    var r = tasmota.scale_uint(transparency, 0, 255, (color_b >> 16) & 0xFF, (color_a >> 16) & 0xFF)
    var g = tasmota.scale_uint(transparency, 0, 255, (color_b >>  8) & 0xFF, (color_a >>  8) & 0xFF)
    var b = tasmota.scale_uint(transparency, 0, 255, (color_b      ) & 0xFF, (color_a      ) & 0xFF)

    var rgb = (r << 16) | (g << 8) | b
    return rgb
  end

  static def apply_bri_gamma(color_a, bri255, gamma)
    if (bri255 == nil)   bri255 = 255       end
    if (bri255 == 0) return 0x000000     end              # if bri is zero, short-cut
    var r = (color_a >> 16) & 0xFF
    var g = (color_a >>  8) & 0xFF
    var b = (color_a      ) & 0xFF

    if (bri255 < 255)                # apply bri
      r = tasmota.scale_uint(bri255, 0, 255, 0, r)
      g = tasmota.scale_uint(bri255, 0, 255, 0, g)
      b = tasmota.scale_uint(bri255, 0, 255, 0, b)
    end

    if gamma
      import light_state
      r = light_state.ledGamma8_8(r)
      g = light_state.ledGamma8_8(g)
      b = light_state.ledGamma8_8(b)
    end
    var rgb = (r << 16) | (g << 8) | b
    return rgb
  end
  
end

return Leds
