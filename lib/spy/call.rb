class Spy::Call
  attr_reader :receiver, :method_name, :args, :block

  def initialize(receiver, method_name, args, block)
    @receiver = receiver
    @method_name = method_name
    @args = args
    @block = block
  end
end
