module Mio
  ## Creating the runtime object model
  
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
      raise "Missing slot: #{name.inspect}"
    end
    
    def []=(name, message)
      @slots[name] = message
    end
    
    # The call method is used to eval an object.
    # By default objects eval to themselves.
    def call(*)
      self
    end
    
    def clone(val=nil)
      val ||= @value && @value.dup rescue TypeError
      Object.new(self, val)
    end
  end
  
  ## Bootstrap the runtime
  object = Object.new
  
  object["clone"]    = proc { |receiver, context| receiver.clone }
  object["set_slot"] = proc { |receiver, context, name, value| receiver[name.call(context).value] = value.call(context) }
  object["println"]  = proc { |receiver, context| puts receiver.value; Lobby["nil"] }
  
  # Introducing the Lobby! Where all the fantastic objects live and also the root context of evaluation.
  Lobby = object.clone
  
  Lobby["Lobby"]   = Lobby
  Lobby["Object"]  = object
  Lobby["nil"]     = object.clone(nil)
  Lobby["true"]    = object.clone(true)
  Lobby["false"]   = object.clone(false)
  Lobby["Number"]  = object.clone(0)
  Lobby["String"]  = object.clone("")
  Lobby["List"]    = object.clone([])
  
  
  ## Creating message object
  
  Lobby["Message"] = object.clone
  
  # Message is a chain of tokens produced when parsing.
  #   1 println.
  # is parsed to:
  #   Message.new("1",
  #               Message.new("println"))
  # You can then +call+ the top level Message to eval it.
  class Message < Object
    attr_accessor :next, :name, :args
    
    def initialize(name)
      @name = name
      @args = []
      
      super(Lobby["Message"])
    end
    
    # Call (eval) the message on the +receiver+.
    def call(receiver, context=receiver, *args)
      case @name
      when ".", "\n" # Terminator
        # reset receiver to object at begining of the chain.
        # eg.:
        #   hello there. yo
        #  ^           ^__ "." resets back to the receiver here
        #  \________________________________________________/
        value = context
        
      when /^\d+/ # Number
        value = Lobby["Number"].clone(@name.to_i)
        
      when /^"(.*)"$/ # String
        value = Lobby["String"].clone($1)
        
      else # Getting the value of a slot
        # Lookup the slot on the receiver
        slot = receiver[name]
        
        # Eval the object in the slot
        value = slot.call(receiver, context, *@args)
        
      end
      
      # Pass to next message if some
      if @next
        @next.call(value, context)
      else
        value
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
      parse_all(code, 1).last
    end
    
    private
      def self.parse_all(code, line)
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
  
  
  ## Creating the method object and helper method.
  
  Lobby["Method"] = object.clone
  Lobby["method"] = proc { |receiver, context, message| Method.new(context, message) }
  
  class Method < Object
    def initialize(context, message)
      @definition_context = context
      @message = message
      super(Lobby["Method"])
    end

    def call(receiver, calling_context, *args)
      # Woo... lots of contexts here... lemme clear dat up, ya:
      #   @definition_context: where the method was defined
      #       calling_context: where the method was called
      #        method_context: where the method body (message) is executing
      method_context = @definition_context.clone
      method_context["self"] = receiver
      method_context["arguments"] = Lobby["List"].clone(args)
      # Note: no argument is evaluated here. Our lil' language only as lazy argument evaluation.
      #       If you pass args to a method, you have to eval them explicitly, using the following
      #       method.
      # Handy method to eval an argument in it's original context.
      method_context["eval_arg"] = proc do |receiver, context, at|
        (args[at.call(context).value] || Lobby["nil"]).call(calling_context)
      end
      @message.call(method_context)
    end
  end
  
  
  ## Putting it all together
  
  def self.eval(code)
    # Parse
    message = Message.parse(code)
    # puts message.to_s
    # Eval
    message.call(Lobby)
  end
  
  
  ## Implementing the language in itself
  
  eval <<-EOS
    ## OO
    
    set_slot("dude", Object clone)
    dude set_slot("name", "Bob")
    # dude name println
    dude set_slot("say_name", method(
      arguments println
      eval_arg(0) println
      self name println
    ))
    dude say_name("hello...")
    
    
    ## Boolean logic
    
    Object set_slot("and", method(
      eval_arg(0)
    ))
    Object set_slot("or", method(
      self
    ))
    
    nil set_slot("and", nil)
    nil set_slot("or", method(
      eval_arg(0)
    ))
    
    false set_slot("and", false)
    false set_slot("or", method(
      eval_arg(0)
    ))
    
    "yo" or("hi") println
    1 and(2 or(3)) println
    
    
    ## Implementing if
    
    set_slot("if", method(
      # eval condition
      set_slot("condition", eval_arg(0))
      condition and( # if true
        eval_arg(1)
      )
      condition or( # if false (else)
        eval_arg(2)
      )
    ))
    
    if(true,
      "condition is true!" println,
      # else
      "nope" println
    )
  EOS
end
