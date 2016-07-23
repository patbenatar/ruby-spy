require 'spy/version'
require 'securerandom'

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
    @all_instances = all_instances
    @spied_methods_map = {}
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
    spied_methods_map.keys.each { |m| remove_spy(m) }
    Spy.unregister(self)
  end

  def dirty?
    spied_methods_map.keys.any?
  end

  private

  attr_reader :all_instances, :spied_methods_map

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
  end

  def remove_spy(method_name)
    aliased_original_method_name = original_method_name(method_name)

    target_obj.send(
      :alias_method,
      method_name,
      aliased_original_method_name
    )

    target_obj.send(:remove_method, aliased_original_method_name)

    spied_methods_map.delete method_name
  end

  def spying_on_class?
    obj.class == Class && !spying_on_all_instances?
  end

  def spying_on_all_instances?
    !!all_instances
  end

  def original_method_name(method_name)
    spied_methods_map[method_name] ||= loop do
      name_candidate = "#{method_name}_#{SecureRandom.hex(8)}".to_sym
      break name_candidate unless all_methods.include? name_candidate
    end
  end
end
