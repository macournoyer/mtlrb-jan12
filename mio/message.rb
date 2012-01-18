module Mio
  Lobby["Message"] = RuntimeObject.clone
  
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
        # x name\n
        # x
        receiver = caller
      when /^\d+/ # Number
        receiver = Lobby["Number"].clone(@name.to_i)
      when /^"(.*)"$/ # String
        receiver = Lobby["String"].clone($1)
      else
        slot = receiver[@name]
        if slot.respond_to?(:call)
          receiver = slot.call(receiver, caller, *@args)
        else
          receiver = slot
        end
      end
      
      if @next
        @next.call(receiver, caller)
      else
        receiver
      end
    end
    
    def to_s(level=0)
      s = "  " * level
      s << "<Message @name=#{@name.inspect}"
      s << ", @args=" + @args.inspect unless @args.empty?
      s << ", @next=\n" + @next.to_s(level + 1) if @next
      s + ">"
    end

    def ==(other)
      @name == other.name && @args == other.args && @next == other.next
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
end