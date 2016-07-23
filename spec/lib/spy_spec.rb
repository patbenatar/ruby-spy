require 'spec_helper'

class MockObject
  attr_reader :method_1_called, :method_2_called

  def initialize
    @method_1_called = false
    @method_with_args_called = false
  end

  def method_1
    @method_1_called = true
  end

  def method_with_args(_arg_1, _arg_2)
    @method_with_args_called = true
    'args response'
  end

  def method_with_block(_arg_1, &_block)
    @method_with_block_called = true
  end
end

describe Spy do
  let(:mock) { MockObject.new }

  before(:each) { Thread.current[Spy::THREAD_LOCAL_ACTIVE_SPIES_KEY] = nil }

  describe '.on' do
    it 'returns a spy' do
      spy = Spy.on(mock)
      expect(spy).to be_an_instance_of Spy
    end

    it 'registers itself with Spy' do
      spy = Spy.on(mock)
      expect(Spy.active_spies).to include spy
    end

    it 'logs calls to any method called on the given object' do
      spy = Spy.on(mock)
      mock.method_1
      expect(spy.calls.count).to eq 1
    end

    it 'calls through to the method on the given object' do
      Spy.on(mock)
      mock.method_1
      expect(mock.method_1_called).to eq true
    end

    it 'raises if the called method does not exist on the given object' do
      Spy.on(mock)
      expect { mock.foo_bar }.to raise_error NoMethodError
    end

    it 'doesnt spy on Ruby Class instance methods' do
      spy = Spy.on(mock)
      mock.to_s

      expect(spy.calls.count).to eq 0
    end

    context 'spy on just one method' do
      it 'logs calls to the given method' do
        spy = Spy.on(mock, :method_1)
        mock.method_1

        expect(spy.calls.count).to eq 1
        expect(spy.calls[0].method_name).to eq :method_1
      end

      it 'does not log calls to other methods' do
        spy = Spy.on(mock, :method_1)
        mock.method_1
        mock.method_with_args('foo', 'bar')

        expect(spy.calls.count).to eq 1
        expect(spy.calls[0].method_name).to eq :method_1
      end
    end

    context 'spy on an instance' do
      let(:another_mock) { MockObject.new }

      it 'spies only the instance, not the class' do
        spy = Spy.on(mock)
        mock.method_1
        another_mock.method_1

        expect(spy.calls.count).to eq 1
      end
    end

    context 'spy on a class' do
      it 'spies on class methods' do
        mock_class = Class.new do
          def self.method_1
          end
        end

        spy = Spy.on(mock_class)
        mock_class.method_1

        expect(spy.calls.count).to eq 1
        expect(spy.calls[0].method_name).to eq :method_1
      end

      it 'doesnt spy on Ruby Class methods' do
        mock_class = Class.new do
          def self.method_1
          end
        end

        spy = Spy.on(mock_class)
        mock_class.constants

        expect(spy.calls.count).to eq 0
      end
    end

    context 'spy on a module' do
      it 'spies on module methods' do
        module MockModule
          def self.method_1
          end
        end

        spy = Spy.on(MockModule)
        MockModule.method_1

        expect(spy.calls.count).to eq 1
        expect(spy.calls[0].method_name).to eq :method_1
      end
    end
  end

  describe '.on_all_instances_of' do
    it 'spies on all instances of a class' do
      mock_class = Class.new do
        def method_1
        end
      end

      spy = Spy.on_all_instances_of(mock_class)

      mock_1 = mock_class.new
      mock_1.method_1

      mock_2 = mock_class.new
      mock_2.method_1

      expect(spy.calls.count).to eq 2
    end
  end

  describe '.clean' do
    it 'cleans up all registered spies' do
      spy = Spy.on(mock)

      mock_2 = MockObject.new
      spy_2 = Spy.on(mock_2, :method_1)

      Spy.clean

      expect(mock.method_1).to eq true
      expect(mock.method_with_args('foo', 'bar')).to eq 'args response'
      expect(mock_2.method_1).to eq true

      expect(spy.calls.count).to eq 0
      expect(spy_2.calls.count).to eq 0
    end

    it 'resets active_spies to empty' do
      Spy.on(mock)
      expect { Spy.clean }.to change { Spy.active_spies.count }.to(0)
    end

    context 'with a block' do
      it 'executes the block' do
        executed = false
        Spy.clean { executed = true }
        expect(executed).to eq true
      end

      it 'cleans up after the execution of the block' do
        Spy.clean do
          spy = Spy.on(mock)
          mock.method_1
          expect(spy.calls.count).to eq 1
        end

        expect(Spy.active_spies.count).to eq 0
      end

      it 'does not clean up the outer scope' do
        outer_spy = Spy.on(mock)

        expect do
          Spy.clean do
            inner_mock = MockObject.new
            inner_spy = Spy.on(inner_mock)
            inner_mock.method_1
            expect(inner_spy.calls.count).to eq 1
          end
        end.not_to change { Spy.active_spies }

        expect(Spy.active_spies).to eq [outer_spy]
      end

      it 'supports nesting of blocks' do
        outer_spy = Spy.on(mock)

        expect do
          Spy.clean do
            inner_1_mock = MockObject.new
            inner_1_spy = Spy.on(inner_1_mock)
            inner_1_mock.method_1

            Spy.clean do
              inner_2_mock = MockObject.new
              inner_2_spy = Spy.on(inner_2_mock)
              inner_2_mock.method_1

              expect(Spy.active_spies).to eq [inner_2_spy]
            end

            expect(Spy.active_spies).to eq [inner_1_spy]
          end
        end.not_to change { Spy.active_spies }

        expect(Spy.active_spies).to eq [outer_spy]
      end

      context 'if the block raises' do
        it 'still cleans up' do
          MockException = Class.new(StandardError)

          expect do
            Spy.clean do
              spy = Spy.on(mock)
              expect(Spy.active_spies).to eq [spy]
              raise MockException
            end
          end.to raise_error MockException

          expect(Spy.active_spies.count).to eq 0
        end
      end
    end
  end

  describe '.register' do
    let(:spy) { double('spy') }

    it 'does not add duplicates' do
      Spy.register(spy)
      Spy.register(spy)
      expect(Spy.active_spies.count).to eq 1
    end

    it 'adds the given spy to the set of active spies' do
      Spy.register(spy)
      expect(Spy.active_spies).to include spy
    end
  end

  describe '#on' do
    context 'spy has previously been cleaned' do
      it 're-registers itself as active with Spy' do
        spy = Spy.on(mock)
        spy.clean

        expect { spy.on(:method_1) }.to change { Spy.active_spies.count }.to(1)
        expect(Spy.active_spies).to include spy
      end
    end
  end

  describe '#on_all' do
    context 'spy has previously been cleaned' do
      it 're-registers itself as active with Spy' do
        spy = Spy.on(mock)
        spy.clean

        expect { spy.on_all }.to change { Spy.active_spies.count }.to(1)
        expect(Spy.active_spies).to include spy
      end
    end
  end

  describe '#calls' do
    it 'returns the set of all calls made to the object' do
      spy = Spy.on(mock)
      mock.method_1
      mock.method_with_args('foo', 'bar')

      expect(spy.calls.count).to eq 2

      expect(spy.calls[0].method_name).to eq :method_1
      expect(spy.calls[1].method_name).to eq :method_with_args
    end

    it 'returns the arguments given with calls' do
      spy = Spy.on(mock)
      mock.method_1
      mock.method_with_args('foo', 'bar')

      expect(spy.calls[0].args).to eq []
      expect(spy.calls[0].block).to eq nil

      expect(spy.calls[1].args).to eq %w(foo bar)
      expect(spy.calls[1].block).to eq nil
    end

    it 'returns the blocks given with calls' do
      spy = Spy.on(mock)
      block = -> {}
      mock.method_with_block('foo', &block)

      expect(spy.calls[0].block).to eq block
    end

    it 'returns the receiver of each call' do
      mock_class = Class.new do
        def method_1
        end
      end

      spy = Spy.on_all_instances_of(mock_class)

      mock_1 = mock_class.new
      mock_1.method_1

      mock_2 = mock_class.new
      mock_2.method_1

      expect(spy.calls[0].receiver).to eq mock_1
      expect(spy.calls[1].receiver).to eq mock_2
    end

    context 'no methods have been called' do
      it 'returns an empty array' do
        spy = Spy.on(mock)
        expect(spy.calls).to eq []
      end
    end

    context 'a specific method name is given' do
      it 'returns only calls to the given method' do
        spy = Spy.on(mock)
        mock.method_1
        mock.method_with_args('foo', 'bar')
        mock.method_1

        expect(spy.calls(:method_1).length).to eq 2
        expect(spy.calls(:method_with_args).length).to eq 1
      end
    end
  end

  describe '#clean' do
    it 'unregisters itself with Spy' do
      spy = Spy.on(mock)
      expect(Spy.active_spies).to include spy
      expect { spy.clean }.to change { Spy.active_spies }
      expect(Spy.active_spies).not_to include spy
    end

    context 'all methods spied on' do
      it 'removes previously created spies' do
        spy = Spy.on(mock)
        spy.clean

        expect(mock.method_1).to eq true
        expect(mock.method_with_args('foo', 'bar')).to eq 'args response'

        expect(spy.calls.count).to eq 0
      end
    end

    context 'one method spied on' do
      it 'removes previously created spies' do
        spy = Spy.on(mock, :method_1)
        spy.clean

        expect(mock.method_1).to eq true

        expect(spy.calls.count).to eq 0
      end
    end

    context 'two methods spied on' do
      it 'removes previously created spies' do
        spy = Spy.on(mock, :method_1)
        spy.on(:method_with_args)
        spy.clean

        expect(mock.method_1).to eq true
        expect(mock.method_with_args('foo', 'bar')).to eq 'args response'

        expect(spy.calls.count).to eq 0
      end
    end
  end

  describe '#dirty?' do
    context 'before spying' do
      it 'is false' do
        spy = Spy.new(mock)
        expect(spy.dirty?).to eq false
      end
    end

    context 'after spying' do
      it 'is true' do
        spy = Spy.on(mock)
        expect(spy.dirty?).to eq true
      end
    end

    context 'after cleaning' do
      it 'is false' do
        spy = Spy.on(mock)
        spy.clean

        expect(spy.dirty?).to eq false
      end
    end
  end
end
