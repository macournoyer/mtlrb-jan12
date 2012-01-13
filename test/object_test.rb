require File.dirname(__FILE__) + '/test_helper'

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
  
  def test_set_slot_from_runtime
    object = Mio::Lobby["Object"].clone
    method_name = Mio::Lobby["String"].clone("x")
    one = Mio::Lobby["Number"].clone(1)
    object["set_slot"].call(object, object, method_name, one) # set_slot("x", 1)
    assert_equal 1, object["x"].value
  end
end