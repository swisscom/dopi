# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dopi/version'

Gem::Specification.new do |spec|
  spec.name          = 'dopi'
  spec.version       = Dopi::VERSION
  spec.authors       = ['Andreas Zuber', 'Andreas Maierhofer']
  spec.email         = ['zuber@puzzle.ch', 'andreas.maierhofer@swisscom.com']
  spec.description   = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.summary       = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-command'

  # Code quality
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rubocop'

  spec.add_runtime_dependency 'dop_common', '~> 0.11', '>= 0.11.0'
  spec.add_runtime_dependency 'gli', '~> 2'
  spec.add_runtime_dependency 'logger-colors', '~> 1'
  spec.add_runtime_dependency 'hiera', '~> 3'
  spec.add_runtime_dependency 'mcollective-client', '~> 2'
  spec.add_runtime_dependency 'winrm', '~> 1'
  spec.add_runtime_dependency 'parallel', '~> 1'

  # curses was removed in ruby 2.1
  if RUBY_VERSION >= '2.1'
    spec.add_runtime_dependency 'curses', '~> 1'
  end
end
