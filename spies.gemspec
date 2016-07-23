# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spy/version'

Gem::Specification.new do |spec|
  spec.name = 'spies'
  spec.version = Spy::VERSION
  spec.authors = ['Nick Giancola']
  spec.email = ['nick@philosophie.is']

  spec.summary = 'Ruby test spies'
  spec.description = 'Ruby test spies'
  spec.homepage = 'https://github.com/patbenatar/ruby-spy'
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
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'redcarpet'
end
