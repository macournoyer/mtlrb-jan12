$:.unshift "."
require "mio/object"
require "mio/message"
require "mio/method"

module Mio
  def self.eval(code)
    message = Message.parse(code)
    message.call(Lobby) if message
  end
  
  def self.load(file)
    eval File.read(File.join(File.dirname(__FILE__), file))
  end
  
  # load "mio/boot.mio"
end