# Ruby Spy [![Build Status](https://travis-ci.org/patbenatar/ruby_spy.svg?branch=master)](https://travis-ci.org/patbenatar/ruby_spy) [![Coverage Status](https://coveralls.io/repos/github/patbenatar/ruby_spy/badge.svg?branch=master)](https://coveralls.io/github/patbenatar/ruby_spy?branch=master)


Test spies for Ruby. Why? For fun.

## Usage

Spy on all methods of an instance:

```ruby
spy = Spy.on(my_object)
spy.some_method
expect(spy.calls.count).to eq 1
expect(spy.calls.last.method_name).to eq :some_method
```

Spy on arguments:

```ruby
spy = Spy.on(my_object)

spy.some_method_with_args('foo', 'bar')
expect(spy.calls.last.args).to eq %w(foo bar)

block = -> {}
spy.some_method_with_block(&block)
expect(spy.calls.last.block).to eq block
```

Spy on one method:

```ruby
spy = Spy.on(my_object, :some_method)
spy.some_method
spy.another_method
expect(spy.calls.count).to eq 1
```

Spy on a constant:

```ruby
spy = Spy.on(SomeClass)
SomeClass.some_method
expect(spy.calls.count).to eq 1
```

Spy on all instances of a class:

```ruby
spy = Spy.on_all_instances_of(SomeClass)

instance_1 = SomeClass.new
instance_1.some_method

instance_2 = SomeClass.new
instance_2.some_method

expect(spy.calls.count).to eq 2
expect(spy.calls[1].receiver).to eq instance_2
```

Clean up after yourself:

```ruby
Spy.clean
```

Or keep a block clean:

```ruby
Spy.clean do
  Spy.on(my_object)
end
```

Cleaning with RSpec:

```ruby
before(:each) { Spy.clean }
```
