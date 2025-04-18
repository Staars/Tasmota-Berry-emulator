#-
 - LED driver for Ulanzi clock written in Berry
 - very simple animation in the style of Matrix
-#

class MATRIX_ANIM
  var strip
  var positions
  var speeds

  def init()
    import Leds
    import math
    self.strip = Leds(32*8, gpio.pin(gpio.WS2812, 0))
    self.strip.set_bri(255)
    self.strip.clear()
    self.positions = []
    self.speeds = []
    print("Ulanzi Matrix Screensaver")
    for i:0..31
      var y = (math.rand()%10) - 3
      if i > 0
        if y == self.positions[i-1]
          y += 3
        end
      end
      self.positions.push(y)
      var speed = (math.rand()%3) + 1
      self.speeds.push(speed)
    end
    tasmota.add_driver(self)
  end

  def deinit()
    self.strip.clear()
    tasmota.remove_driver(self)
  end

  def getPos(x,y)
    if y & 0x1
       return y * 32 + (31 - x) # y * xMax + (xMax - 1 - x) 
    end
    return y * 32 + x # y * xMax + x
  end

  def set_pixel_color(pos,color)
    if pos >= 0 &&  pos < 256
      self.strip.set_pixel_color(pos,color)
    end
  end

  def every_50ms()
    import math
    var x = 0
    while x < 32
      y = self.positions[x]

      var speed = self.speeds[x]
      if speed > 0
        self.speeds[x] = speed - 1
      else
      self.speeds[x] = (math.rand()%5)

        if y == 9
          self.positions[x] = -2
        else
          var pos = self.getPos(x,y-1)
          self.set_pixel_color(pos,0)

          var color = 255 << 8
          pos = self.getPos(x,y)
          self.set_pixel_color(pos,color)

          y += 1
          color = 200 << 8
          pos = self.getPos(x,y)
          self.set_pixel_color(pos,color)

          y += 1
          color = 150 << 8
          pos = self.getPos(x,y)

          self.set_pixel_color(pos,color)

          y += 1
          color = 100 << 8
          pos = self.getPos(x,y)
          self.set_pixel_color(pos,color)

          self.positions[x] = y - 2
        end
      end
      x += 1
    end
    self.strip.show()
  end
end

var a =  MATRIX_ANIM()