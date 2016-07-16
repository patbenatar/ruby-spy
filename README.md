# Ruby Spy [![Build Status](https://travis-ci.org/patbenatar/ruby_spy.svg?branch=master)](https://travis-ci.org/patbenatar/ruby_spy)

Test spies for Ruby. Why? For fun.

## Usage

Spy on all methods of an instance:

```ruby
spy = Spy.on(my_object)
spy.some_method
expect(spy.calls.count).to eq 1
expect(spy.calls.first.method_name).to eq :some_method
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
SomeClass.new.some_method
SomeClass.new.some_method
expect(spy.calls.count).to eq 2
```
