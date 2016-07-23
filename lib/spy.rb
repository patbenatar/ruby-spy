require 'spy/version'

class Spy
  autoload :Call, 'spy/call'

  THREAD_LOCAL_ACTIVE_SPIES_KEY = 'ruby_spy_active_spies'.freeze

  def self.active_spies
    Thread.current[THREAD_LOCAL_ACTIVE_SPIES_KEY] ||= []
  end

  def self.register(spy)
    active_spies << spy unless active_spies.include? spy
  end

  def self.unregister(spy)
    active_spies.delete(spy)
  end

  def self.on(obj, method_name = nil)
    spy_with_options(obj, method_name)
  end

  def self.on_all_instances_of(obj, method_name = nil)
    spy_with_options(obj, method_name, all_instances: true)
  end

  def self.spy_with_options(obj, method_name, options = {})
    new(obj, options).tap do |spy|
      method_name ? spy.on(method_name) : spy.on_all
      Spy.register(spy)
    end
  end

  def self.clean
    if block_given?
      outer_active_spies = active_spies
      Thread.current[THREAD_LOCAL_ACTIVE_SPIES_KEY] = nil

      begin
        yield
      ensure
        clean
        Thread.current[THREAD_LOCAL_ACTIVE_SPIES_KEY] = outer_active_spies
      end
    else
      active_spies.dup.each(&:clean)
    end
  end

  attr_reader :obj

  def initialize(obj, all_instances: false)
    @obj = obj
    @calls = []
    @actively_spied_methods = []
    @all_instances = all_instances
  end

  def on_all
    all_methods.each { |m| spy_on(m) }
    Spy.register(self)
  end

  def on(method_name)
    spy_on(method_name)
    Spy.register(self)
  end

  def calls(method_name = nil)
    if method_name
      @calls.select { |c| c.method_name == method_name }
    else
      @calls
    end
  end

  def clean
    actively_spied_methods.dup.each { |m| remove_spy(m) }
    Spy.unregister(self)
  end

  def dirty?
    actively_spied_methods.any?
  end

  private

  attr_reader :all_instances, :actively_spied_methods

  def all_methods
    if spying_on_class?
      obj.methods - Class.methods
    elsif spying_on_all_instances?
      obj.instance_methods - Class.instance_methods
    else
      obj.methods - Class.instance_methods
    end
  end

  def singleton_class
    class << obj; self; end
  end

  def target_obj
    spying_on_all_instances? ? obj : singleton_class
  end

  def spy_on(method_name)
    spy = self
    aliased_original_method_name = original_method_name(method_name)

    target_obj.send(
      :alias_method,
      aliased_original_method_name,
      method_name
    )

    target_obj.send(:define_method, method_name) do |*args, &block|
      spy.calls << Call.new(self, method_name, args, block)
      send aliased_original_method_name, *args, &block
    end

    actively_spied_methods << method_name
  end

  def remove_spy(method_name)
    aliased_original_method_name = original_method_name(method_name)

    target_obj.send(
      :alias_method,
      method_name,
      aliased_original_method_name
    )

    target_obj.send(:remove_method, aliased_original_method_name)

    actively_spied_methods.delete(method_name)
  end

  def spying_on_class?
    obj.class == Class && !spying_on_all_instances?
  end

  def spying_on_all_instances?
    !!all_instances
  end

  def original_method_name(method_name)
    "#{method_name}_before_spy".to_sym
  end
end
