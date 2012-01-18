require File.dirname(__FILE__) + '/test_helper'

class ObjectTest < Test::Unit::TestCase
  def test_lookup
    proto = Mio::Object.new
    object = proto.clone
    
    proto["x"] = 1
    assert_equal 1, object["x"]
    
    object["x"] = 2
    assert_equal 2, object["x"]
  end
  
  def test_call_method
    # set_slot("object", Object clone)
    object = Mio::Lobby["Object"].clone
    # object set_slot("x", "works!")                 
    object["x"] = Mio::Lobby["String"].clone("works!")  
    
    assert_prints("works!\n") do
      receiver = object["x"]
      # object x println
      receiver["println"].call(receiver, Mio::Lobby)    
    end
  end
end