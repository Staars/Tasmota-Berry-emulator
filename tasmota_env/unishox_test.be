import unishox

var samples = ["", "hello world", "ON Rules#Timer=1 DO Power1 TOGGLE ENDON"]
for sample: samples
  var packed = unishox.compress(sample)
  if unishox.decompress(packed) != sample
    raise "unishox round-trip failed"
  end
end

print("=== unishox smoke test OK")
