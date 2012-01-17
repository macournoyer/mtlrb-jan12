module Mio
  Lobby["Method"] = RuntimeObject.clone
  
  class Method < Object
    def initialize(message)
      @message = message
      super(Lobby["Method"])
    end
    
    def call(receiver, caller, *args)
      context = caller.clone
      context["self"] = receiver
      context["caller"] = caller
      context["arguments"] = Lobby["List"].clone(args)
      
      @message.call(context)
    end
  end
  
  Lobby["method"] = proc do |receiver, caller, message|
    Method.new(message)
  end
end