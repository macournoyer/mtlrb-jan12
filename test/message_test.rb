require File.dirname(__FILE__) + '/test_helper'

class MessageTest < Test::Unit::TestCase
  def test_eval_message_chain
    m = Mio::Message.new("set_slot", [Mio::Message.new('"x"'), Mio::Message.new("1")],
          Mio::Message.new("\n", [],
            Mio::Message.new("x")))
          
    assert_equal 1, m.call(Mio::Lobby).value
  end
  
  def test_parse
    m = Mio::Message.parse(<<-EOS)
      set_slot("x", 1)
      x
    EOS
    
    assert_equal 1, m.call(Mio::Lobby).value
  end
end