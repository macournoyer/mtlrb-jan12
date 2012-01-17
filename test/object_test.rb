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
    object = Mio::Lobby["Object"].clone
    object["x"] = Mio::Lobby["String"].clone("works!")
    receiver = object["x"]
    
    assert_prints("works!\n") { receiver["println"].call(receiver, Mio::Lobby) }
  end
end