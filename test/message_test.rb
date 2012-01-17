require File.dirname(__FILE__) + '/test_helper'

class MessageTest < Test::Unit::TestCase
  def test_parse
    message = Mio::Message.parse(<<-EOS)
      set_slot("x", 1)
      x
    EOS
    
    # expected[TAB]
    expected = Mio::Message.new("set_slot", [Mio::Message.new('"x"'), Mio::Message.new("1")],
                 Mio::Message.new("\n", [],
                   Mio::Message.new("x")))
    
    assert_equal expected, message
  end
  
  def test_eval
    message = Mio::Message.parse(<<-EOS)
      set_slot("x", 1)
      x
    EOS
    
    assert_equal 1, message.call(Mio::Lobby).value
  end
end