# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dopi/version'

Gem::Specification.new do |spec|
  spec.name          = "dopi"
  spec.version       = Dopi::VERSION
  spec.authors       = ["Andreas Zuber"]
  spec.email         = ["zuber@puzzle.ch"]
  spec.description   = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.summary       = %q{DOPi orchestrates puppet runs, mco calls and custom commands over different nodes}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "hiera"
  spec.add_runtime_dependency "mcollective-client" 
end
