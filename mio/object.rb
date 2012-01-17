module Mio
  class Object
    attr_accessor :slots, :proto, :value
    
    def initialize(proto=nil, value=nil)
      @proto = proto
      @value = value
      @slots = {}
    end
    
    # object[name] => object.[](name)
    def [](name)
      return @slots[name] if @slots.key?(name)
      return @proto[name] if @proto
      raise "Slot not found: #{name}"
    end
    
    # object[name] = value
    def []=(name, value)
      @slots[name] = value
    end
    
    def clone(value=nil)
      Object.new(self, value)
    end
  end
  
  RuntimeObject = Object.new
  
  RuntimeObject["clone"] = proc do |receiver, caller|
    receiver.clone
  end
  
  RuntimeObject["set_slot"] = proc do |receiver, caller, name, value|
    name = name.call(caller).value
    receiver[name] = value.call(caller)
  end
  
  RuntimeObject["println"] = proc do |receiver, caller|
    puts receiver.value
    Lobby["nil"]
  end
  
  Lobby = RuntimeObject.clone
  Lobby["Lobby"] = Lobby
  Lobby["Object"] = RuntimeObject
  Lobby["nil"] = RuntimeObject.clone(nil)
  Lobby["true"] = RuntimeObject.clone(true)
  Lobby["false"] = RuntimeObject.clone(false)
  Lobby["Number"] = RuntimeObject.clone
  Lobby["String"] = RuntimeObject.clone
  Lobby["List"] = RuntimeObject.clone
  
  Lobby["List"]["at"] = proc do |receiver, caller, index|
    index = index.call(caller).value
    array = receiver.value
    array[index]
  end
end