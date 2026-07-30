class MinimalDriver
  var counter

  def init()
    print("MinimalDriver: init called")
    self.counter = 0
  end

  def every_second()
    self.counter = self.counter + 1
    print("MinimalDriver: tick " + str(self.counter) + " at " + str(tasmota.millis()))
  end

  def web_add_button()
    print("MinimalDriver: web_add_button called")
  end
end

return MinimalDriver()