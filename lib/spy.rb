require 'spy/version'
require 'securerandom'

class Spy
  autoload :Call, 'spy/call'

  THREAD_LOCAL_ACTIVE_SPIES_KEY = 'ruby_spy_active_spies'.freeze

  ##
  # Active spies in the current thread.
  #
  # @return [Array<Spy>] instances of `Spy` that have active method spies on
  #                      their target obj
  #
  def self.active_spies
    Thread.current[THREAD_LOCAL_ACTIVE_SPIES_KEY] ||= []
  end

  def self.register(spy)
    active_spies << spy unless active_spies.include? spy
  end

  def self.unregister(spy)
    active_spies.delete(spy)
  end

  ##
  # Spy on an instance, class, or module.
  #
  # By default, this will spy on all user-defined methods (not methods defined
  # on Ruby's base Class).
  #
  # @param obj [Object] the instance, class, or module to spy on
  # @param method_name [Symbol] optionally limit spying to a single method
  #
  # @return [Spy] an active instance of `Spy` for the given `obj`
  #
  def self.on(obj, method_name = nil)
    spy_with_options(obj, method_name)
  end

  ##
  # Spy on all instances of a class.
  #
  # By default, this will spy on all user-defined methods (not methods defined
  # on Ruby's base Class).
  #
  # @param obj [Object] the class to spy on
  # @param method_name [Symbol] optionally limit spying to a single method
  #
  # @return [Spy] an active instance of `Spy` for the given `obj`
  #
  def self.on_all_instances_of(obj, method_name = nil)
    spy_with_options(obj, method_name, all_instances: true)
  end

  def self.spy_with_options(obj, method_name, options = {})
    new(obj, options).tap do |spy|
      method_name ? spy.on(method_name) : spy.on_all
      Spy.register(spy)
    end
  end

  ##
  # Remove all active Spy instances in the current thread and restore their
  # spied methods to the original state.
  #
  # @yield Optionally provide a block, and spies created within the block will
  #        be cleaned, leaving the outer scope untouched. Blocks can be nested.
  #
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

  # @return [Object] the instance, class, or module being spied on by this spy
  attr_reader :obj

  def initialize(obj, all_instances: false)
    @obj = obj
    @calls = []
    @all_instances = all_instances
    @spied_methods_map = {}
  end

  ##
  # Spy on all user-defined methods on `obj`
  #
  # @return [Spy] self
  #
  def on_all
    all_methods.each { |m| spy_on(m) }
    Spy.register(self)
    self
  end

  ##
  # Spy on a single method on `obj`
  #
  # @param method_name [Symbol] the method to spy on
  #
  # @return [Spy] self
  #
  def on(method_name)
    spy_on(method_name)
    Spy.register(self)
    self
  end

  ##
  # Information about the calls received by this spy
  #
  # @param method_name [Symbol] optionally filter results to the given method
  #
  # @return [Array<Call>] set of `Call` objects containing information about
  #                       each method call since the spy was activated.
  #
  def calls(method_name = nil)
    if method_name
      @calls.select { |c| c.method_name == method_name }
    else
      @calls
    end
  end

  ##
  # Remove spy and return spied methods on `obj` to the original state.
  #
  # @return [Spy] self
  #
  def clean
    spied_methods_map.keys.each { |m| remove_spy(m) }
    Spy.unregister(self)
    self
  end

  ##
  # Check if spy is actively spying on any methods on `obj`
  #
  # @return [Boolean] dirty state
  #
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
