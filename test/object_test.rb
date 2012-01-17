require File.dirname(__FILE__) + '/test_helper'

class ObjectTest < Test::Unit::TestCase
  def test_lookup
    proto = Mio::Object.new
    object = Mio::Object.new(proto)
    
    proto["x"] = 1
    assert_equal 1, object["x"]
    
    object["x"] = 2
    assert_equal 2, object["x"]
  end
  
  def test_call_method
    object = Mio::Lobby["Object"].clone                 # set_slot("object", Object clone)
    object["x"] = Mio::Lobby["String"].clone("works!")  # object set_slot("x", "works!")
    
    assert_prints("works!\n") do
      receiver = object["x"]
      receiver["println"].call(receiver, Mio::Lobby)    # object x println
    end
  end
end