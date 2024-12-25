#################################################################################
# webclient class - only for emulator!!
#
# uses urlfetch to simulate GET requests
#################################################################################

class webclient
  var temp_file, url

  def init()
      import uuid
      self.temp_file = "tmp/" + uuid.uuid4() + "_wc"
  end

  def begin(url)
      self.url = url
  end

  def GET()
    if self.url == nil
      print("no url")
    end
    if tasmota.urlfetch(self.url, self.temp_file)
      return 200
    else
      return 404
    end
  end

  def get_string()
    var f = open(self.temp_file,"r")
    var s = f.read()
    f.close()
    return s
  end

  def write_file(f)
    print("no support in emulator")
  end
end