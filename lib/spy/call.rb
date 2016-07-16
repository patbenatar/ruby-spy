class Spy::Call
  attr_reader :method_name, :args, :block

  def initialize(method_name, args, block)
    @method_name = method_name
    @args = args
    @block = block
  end
end
