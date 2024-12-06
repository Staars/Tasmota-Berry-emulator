class UANIM
  var color, cycles, delay, mode
  var clist, clist_initial
  var steps

  def init(color, cycles, delay, mode)
    self.color = color
    self.cycles = cycles
    self.delay = delay
    self.mode = mode
    self.colorFromSeed()
    self.clist = [0,0,0,0,0,0,0,0]
    self.steps = 0
  end

  def colorFromSeed()
    var divider = 8
    if  self.mode == 2 ||  self.mode == 3
      divider = 9
    end
    var r = (((self.color >> 16) / divider) << 16) & 0xff0000
    var g = ((((self.color >> 8) & 0xff) / divider) << 8) & 0xff00
    var b = (((self.color & 0xff) / divider))
    var step = r | g | b

    var clist = [self.color,0,0,0,0,0,0,0]
    var pos = 1..7
    for i:pos
      clist[i] = clist[i-1] - step
    end
    if self.mode == 2 || self.mode == 3
      clist = clist[4..7] + clist[4..7].reverse()
    end
    self.clist_initial = clist
    if self.mode == 4
      self.steps = 8
      self.updateCList()
    end
  end

  def clearFirst()
    if self.steps < 8
      var r = 0..(7-self.steps)
      for i:r
        self.clist[i] = 0
      end
    end
  end

  def rotate_up()
    var last = self.clist_initial[0]
    var r = 0..6
    for i:r
      self.clist_initial[i] = self.clist_initial[i+1]
    end
    self.clist_initial[7] = last
    self.clist = self.clist_initial.copy()
  end

  def rotate_down()
    var first = self.clist_initial[7]
    r = range(6,0,-1)
    for i:r
      self.clist_initial[i+1] = self.clist_initial[i]
    end
    self.clist_initial[0] = first
    self.clist = self.clist_initial.copy()
  end


  def updateCList()
    var step = self.cycles
    var mode = self.mode
    if mode == 0 || mode == 2 || mode == 4
      self.rotate_up()
      if mode == 4 self.clearFirst() end
    elif mode == 1 || mode == 3 || mode == 5
      self.rotate_down()
      if mode == 5 self.clist[0] = 0 end
    end
    self.steps += 1
  end

  def run()
    self.cycles -= 1
    if  self.cycles < 0
      return true
    else
      return false
    end
  end

end

class ULANIM
  var cmatrix
  var strip
  var animation, delay
  var ca # current_animation

  def init()
    self.strip = Leds(32 * 8, gpio.pin(gpio.WS2812, 32))
    self.strip.set_bri(256)
    self.initCMatrix()
    self.loadAnimation()
    tasmota.add_fast_loop(/->self.loop())
    tasmota.add_driver(self)
  end

  def loop()
    if self.ca == nil
      return
    end
    if self.delay > 0 #speed/delay
      self.delay -= 1
      return
    end
    self.draw()
    self.ca.updateCList()
    self.nextAnimation()
  end

  def loadAnimation()
    self.animation = [ # seed_color, cycles, delay, mode
    UANIM(0x1010ff,48,16,2),
    UANIM(0x1010ff,16,4,4),
    UANIM(0x1010ff,8,8,5),
    UANIM(0xff11ff,48,12,2),
    UANIM(0xff11ff,16,4,0),
    UANIM(0xff11ff,8,8,5),
    UANIM(0x0000ff,8,0,2),
    UANIM(0x0000ff,7,0,3),
    UANIM(0x00ffff,8,2,2),
    UANIM(0x00ffff,7,2,3),
    UANIM(0x00ff00,8,0,0),
    UANIM(0x00ff00,7,1,1),
    UANIM(0xffff00,64,20,2),
    UANIM(0xffff00,7,20,5),
    UANIM(0xff0000,8,1,4),
    UANIM(0xff0000,7,1,1),
    UANIM(0xffffff,8,1,2),
    UANIM(0xffffff,8,1,3)
    ]
    self.ca = UANIM(0,0,0,0)
    self.delay = 0
  end

  def nextAnimation()
    if self.ca.run() == true # true if finished
      if size(self.animation) == 0
        print("delete anims",self.animation)
        self.ca = nil
        return
      end
      self.ca = self.animation[0]
      self.animation = self.animation[1..]
      print("## next animation",self.ca)
    end
    self.delay = self.ca.delay
  end

  def draw()
    var setc = /i,c->self.strip.set_pixel_color(i,c)
    var cl = self.ca.clist
    var cm = self.cmatrix
    var r = 0..255
    for i:r
      setc(i,cl[cm[i]])
    end
    self.strip.show()
  end

  def initCMatrix()
    var offset = [0]
    self.cmatrix = bytes(-256)
    for y:0..7
      for x:0..31
        for o:offset
          if x >= o && x < (32 - o)
            self.cmatrix[32*y + x] = o
          end
        end
      end
      offset.push(offset[-1]+1)
    end
  end
end

return ULANIM()