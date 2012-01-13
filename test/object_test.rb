require "test/unit"
require "mio"

class ObjectTest < Test::Unit::TestCase
  def test_lookup_in_protos
    proto = Mio::Object.new
    object = Mio::Object.new(proto)
    proto["x"] = 1
    assert_equal 1, object["x"]
  end
  
  def test_clone
    object = Mio::Object.new(nil, [])
    assert_not_nil object.value
    assert_equal object.value, object.clone.value
    assert_not_same object.value, object.clone.value
  end
end