module Mio
  # Lobby["Method"] = RuntimeObject.clone
  
  class Method < Object
    def initialize(message)
      @message = message
      super(Lobby["Method"])
    end
  end
end