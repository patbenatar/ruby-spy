# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spy/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby_spy'
  spec.version = Spy::VERSION
  spec.authors = ['Nick Giancola']
  spec.email = ['nick@gophilosophie.com']

  spec.summary = 'Ruby test spy'
  spec.description = 'Ruby test spy'
  spec.homepage = 'https://github.com/patbenatar/ruby_spy'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`
               .split("\x0")
               .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.7', '>= 4.7.2'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
  spec.add_development_dependency 'rubocop', '~> 0.41.2'
end
