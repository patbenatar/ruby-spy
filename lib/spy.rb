require 'spy/version'

class Spy
  autoload :Call, 'spy/call'

  def self.on(obj, method_name = nil)
    new(obj, method_name)
  end

  attr_reader :obj

  def initialize(obj, method_name = nil)
    @obj = obj
    @calls = []

    if method_name
      spy_on(method_name)
    else
      all_methods.each { |m| spy_on(m) }
    end
  end

  def calls(method_name = nil)
    if method_name
      @calls.select { |c| c.method_name == method_name }
    else
      @calls
    end
  end

  private

  def all_methods
    obj.methods - Class.instance_methods
  end

  def singleton_class
    class << obj; self; end
  end

  def spy_on(method_name)
    spy = self
    aliased_original_method_name = "#{method_name}_before_spy".to_sym

    singleton_class.send(
      :alias_method,
      aliased_original_method_name,
      method_name
    )

    obj.define_singleton_method(method_name) do |*args, &block|
      spy.calls << Call.new(method_name, args, block)
      spy.obj.send aliased_original_method_name, *args, &block
    end
  end
end
