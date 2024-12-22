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

  def create_matrix(w, h, offset)
    offset = int(offset)
    w = int(w)
    h = int(h)
    if offset == nil   offset = 0 end
    if w * h + offset > self.leds || h < 0 || w < 0 || offset < 0
      raise "value_error", "out of range"
    end

    # inner class
    class Leds_matrix
      var strip
      var offset
      var h, w
      var alternate     # are rows in alternate mode (even/odd are reversed)
      var pix_buffer
      var pix_size
    
      def init(strip, w, h, offset)
        self.strip = strip
        self.offset = offset
        self.h = h
        self.w = w
        self.alternate = false

        self.pix_buffer = self.strip.pixels_buffer()
        self.pix_size = self.strip.pixel_size()
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
        if bool(force) || (self.offset == 0 && self.w * self.h == self.strip.leds)
          self.strip.show()
          self.pix_buffer = self.strip.pixels_buffer(self.pix_buffer)  # update buffer after show()
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
        return self.strip.pixels_buffer()
      end
      def pixel_size()
        return self.pix_size
      end
      def pixel_count()
        return self.w * self.h
      end
      def pixel_offset()
        return self.offset
      end
      def clear_to(col, bri)
        if (bri == nil)   bri = self.bri    end
        self.strip.clear_to(col, bri)
        #self.strip.call_native(9, self.strip.to_gamma(col, bri), self.offset, self.w * self.h)
      end
      def set_pixel_color(idx, col, bri)
        if (bri == nil)   bri = self.bri    end
        self.strip.set_pixel_color(idx + self.offset, col, bri)
      end
      def get_pixel_color(idx)
        return self.strip.get_pixel_color(idx + self.offseta)
      end

      # setbytes(row, bytes)
      # sets the raw bytes for `row`, copying at most 3 or 4 x col  bytes
      def set_bytes(row, buf, offset, len)
        var h_bytes = self.h * self.pix_size
        if (len > h_bytes)  len = h_bytes end
        var offset_in_matrix = (self.offset + row) * h_bytes
        self.pix_buffer.setbytes(offset_in_matrix, buf, offset, len)
      end

      # Leds_matrix specific
      def set_alternate(alt)
        self.alternate = alt
      end
      def get_alternate()
        return self.alternate
      end

      def set_matrix_pixel_color(x, y, col, bri)
        if (bri == nil)   bri = self.bri    end
        if self.alternate && x % 2
          # reversed line
          self.strip.set_pixel_color(x * self.w + self.h - y - 1 + self.offset, col, bri)
        else
          self.strip.set_pixel_color(x * self.w + y + self.offset, col, bri)
        end
      end

      def scroll(direction, outshift, inshift) # 0 - up, 1 - left, 2 - down, 3 - right ; outshift mandatory, inshift optional
        var buf = self.pix_buffer
        var h = self.h
        var sz = self.w * 3 # row size in bytes
        var pos
        if direction%2 == 0 #up/down
          if direction == 0 #up
            outshift.setbytes(0,(buf[0..sz-1]).reverse(0,nil,3))
            var line = 0
            while line < (h-1)
              pos = 0
              var offset_dst = line * sz
              var offset_src = ((line+2) * sz) - 3
              while pos < sz
                var dst = pos + offset_dst
                var src = offset_src - pos
                buf[dst] = buf[src]
                buf[dst+1] = buf[src+1]
                buf[dst+2] = buf[src+2]
                pos += 3
              end
              line += 1
            end
            var lastline = inshift ? inshift : outshift
            if h%2 == 1
              lastline.reverse(0,nil,3)
            end
            buf.setbytes((h-1) * sz, lastline)
          else # down
            outshift.setbytes(0,(buf[size(buf)-sz..]).reverse(0,nil,3))
            var line = h - 1
            while line > 0
              buf.setbytes(line * sz,(buf[(line-1) * sz..line * sz-1]).reverse(0,nil,3))
              line -= 1
            end
            var lastline = inshift ? inshift : outshift
            if h%2 == 1
              lastline.reverse(0,nil,3)
            end
            buf.setbytes(0, lastline)
          end
        else # left/right
          var line = 0
          var step = 3
          if direction == 3 # right
            step *= -1
          end
          while line < h
            pos = line * sz
            if step > 0
                var line_end = pos + sz - step
                outshift[(line * 3)] = buf[pos]
                outshift[(line * 3) + 1] = buf[pos+1]
                outshift[(line * 3) + 2] = buf[pos+2]
                while pos < line_end
                  buf[pos] = buf[pos+3]
                  buf[pos+1] = buf[pos+4]
                  buf[pos+2] = buf[pos+5]
                  pos += step
                end
                if inshift == nil
                  buf[line_end] = outshift[(line * 3)]
                  buf[line_end+1] = outshift[(line * 3) + 1]
                  buf[line_end+2] = outshift[(line * 3) + 2]
                else
                  buf[line_end] = inshift[(line * 3)]
                  buf[line_end+1] = inshift[(line * 3) + 1]
                  buf[line_end+2] = inshift[(line * 3) + 2]
                end
              else
                var line_end = pos
                pos = pos + sz + step
                outshift[(line * 3)] = buf[pos]
                outshift[(line * 3) + 1] = buf[pos+1]
                outshift[(line * 3) + 2] = buf[pos+2]
                while pos > line_end
                  buf[pos] = buf[pos-3]
                  buf[pos+1] = buf[pos-2]
                  buf[pos+2] = buf[pos-1]
                  pos += step
                end
                if inshift == nil
                  buf[line_end] = outshift[(line * 3)]
                  buf[line_end+1] = outshift[(line * 3) + 1]
                  buf[line_end+2] = outshift[(line * 3) + 2]
                else
                  buf[line_end] = inshift[(line * 3)]
                  buf[line_end+1] = inshift[(line * 3) + 1]
                  buf[line_end+2] = inshift[(line * 3) + 2]
                end
              end
              step *= -1
              line += 1
          end
        end
      end
    end

    return Leds_matrix(self, w, h, offset)

  end

  static def matrix(w, h, gpio, rmt)
    var strip = Leds(w * h, gpio, rmt)
    var matrix = strip.create_matrix(w, h, 0)
    return matrix
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
