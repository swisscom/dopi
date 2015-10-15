# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dopi/version'

Gem::Specification.new do |spec|
  spec.name          = "dopi"
  spec.version       = Dopi::VERSION
  spec.authors       = ["Andreas Zuber", "Andreas Maierhofer"]
  spec.email         = ["zuber@puzzle.ch", "andreas.maierhofer@swisscom.com"]
  spec.description   = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.summary       = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-mocks"

  # Code quality
  spec.add_development_dependency "simplecov"

  spec.add_runtime_dependency "dop_common"
  spec.add_runtime_dependency "gli"
  spec.add_runtime_dependency "logger-colors"
  spec.add_runtime_dependency "hiera"
  spec.add_runtime_dependency "mcollective-client"
  spec.add_runtime_dependency "winrm"
  spec.add_runtime_dependency "parallel"
  spec.add_runtime_dependency "deep_merge"
end
