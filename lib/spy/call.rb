class Spy::Call
  # @return [Object] object that received the method call
  attr_reader :receiver

  # @return [Symbol] name of the method called
  attr_reader :method_name

  # @return [Array<Object>] arguments given to the method call
  attr_reader :args

  # @return [Proc] block given to the method call, if present
  attr_reader :block

  def initialize(receiver, method_name, args, block)
    @receiver = receiver
    @method_name = method_name
    @args = args
    @block = block
  end
end
