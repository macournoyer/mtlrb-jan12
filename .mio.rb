module Mio
  class Object
    attr_accessor :slots, :protos, :value
    
    def initialize(proto=nil, value=nil)
      @protos = [proto].compact
      @value = value
      @slots = {}
    end
    
    def [](name)
      return @slots[name] if @slots.key?(name)
      message = nil
      @protos.each { |proto| return message if message = proto[name] }
      raise "Missing slot: #{name}"
    end
    
    def []=(name, value)
      @slots[name] = value
    end
    
    def clone(value=nil)
      Object.new(self, value)
    end
    
    # Eval
    def call(*)
      self
    end
  end
  
  ## Bootstrap the runtime

  object = Object.new

  object["clone"] = proc do |receiver, caller|
    receiver.clone
  end

  object["set_slot"] = proc do |receiver, caller, name, value|
    name = name.call(caller).value
    receiver[name] = value.call(caller)
  end

  object["println"] = proc do |receiver, caller|
    puts receiver.value
    Lobby["nil"]
  end

  Lobby = object.clone

  Lobby["Lobby"] = Lobby
  Lobby["Object"] = object
  Lobby["nil"] = object.clone(nil)
  Lobby["true"] = object.clone(true)
  Lobby["false"] = object.clone(false)
  Lobby["Number"] = object.clone
  Lobby["String"] = object.clone
  Lobby["List"] = object.clone
  Lobby["List"]["at"] = proc do |receiver, caller, index|
    array = receiver.value
    index = index.call(caller).value
    array[index]
  end
  
  Lobby["Message"] = object.clone
  
  class Message < Object
    attr_accessor :name, :args, :next
    
    def initialize(name, args=[], next_message=nil)
      @name = name
      @args = args
      @next = next_message
      
      super(Lobby["Message"])
    end
    
    def call(receiver, caller=receiver)
      case @name
      when "\n"
        receiver = caller
      
      when /^\d+/ # Number
        receiver = Lobby["Number"].clone(@name.to_i)
        
      when /^"(.*)"$/ # String
        receiver = Lobby["String"].clone($1)
        
      else
        slot = receiver[name]
        receiver = slot.call(receiver, caller, *@args)
      end
      
      if @next
        @next.call(receiver, caller)
      else
        receiver
      end
    end
    
    def to_s(level=0)
      s = "  " * level
      s << "<Message @name=#{@name}"
      s << ", @args=" + @args.inspect unless @args.empty?
      s << ", @next=\n" + @next.to_s(level + 1) if @next
      s + ">"
    end

    # Parse a string into a chain of messages
    def self.parse(code)
      parse_all(code).last
    end

    private
      def self.parse_all(code, line=1)
        code = code.strip
        i = 0
        message = nil
        messages = []
        
        # Marrrvelous parsing code!
        while i < code.size
          case code[i..-1]
          when /\A("[^"]*")/, # string
               /\A(\.)+/, # dot
               /\A(\n)+/, # line break
               /\A(\w+|[=\-\+\*\/<>]|[<>=]=)/i # name
            m = Message.new($1)
            if messages.empty?
              messages << m
            else
              message.next = m
            end
            line += $1.count("\n")
            message = m
            i += $1.size - 1
          when /\A(\(\s*)/ # arguments
            start = i + $1.size
            level = 1
            while level > 0 && i < code.size
              i += 1
              level += 1 if code[i] == ?\(
              level -= 1 if code[i] == ?\)
            end
            line += $1.count("\n")
            code_chunk = code[start..i-1]
            message.args = parse_all(code_chunk, line)
            line += code_chunk.count("\n")
          when /\A,(\s*)/
            line += $1.count("\n")
            messages.concat parse_all(code[i+1..-1], line)
            break
          when /\A(\s+)/, # ignore whitespace
               /\A(#.*$)/ # comments
            line += $1.count("\n")
            i += $1.size - 1
          else
            raise "Unknow char #{code[i].inspect} at line #{line}"
          end
          i += 1
        end
        messages
      end
  end
  
  Lobby["Message"]["eval_on"] = proc do |receiver, caller, on|
    on = on.call(caller)
    receiver.call(on)
  end
  
  
  Lobby["Method"] = object.clone
  
  class Method < Object
    def initialize(message)
      @message = message
      super(Lobby["Method"])
    end
    
    def call(receiver, caller=receiver, *args)
      context = caller.clone
      context["self"] = receiver
      context["arguments"] = Lobby["List"].clone(args)
      context["caller"] = caller
      
      @message.call(context)
    end
  end
  
  Lobby["method"] = proc do |receiver, caller, message|
    Method.new(message)
  end
  
  def self.eval(code)
    message = Message.parse(code)
    message.call(Lobby)
  end
  
  def self.load(file)
    eval File.read(file)
  end
  
  load "boot.mio"
end

# if __FILE__ == $PROGRAM_NAME
#   if ARGV.empty?
#     require "readline"
#     loop do
#       line = Readline::readline('>> ')
#       Readline::HISTORY.push(line)
#       p Mio.eval(line).value rescue puts $!
#     end
#   else
#     Mio.load(ARGV.first)
#   end
# end