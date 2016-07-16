# frozen_string_literal: true

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
  end

  def method_with_block(_arg_1, &_block)
    @method_with_block_called = true
  end
end

describe Spy do
  let(:mock) { MockObject.new }

  describe '.on' do
    it 'returns a spy' do
      spy = Spy.on(mock)
      expect(spy).to be_an_instance_of Spy
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
end
