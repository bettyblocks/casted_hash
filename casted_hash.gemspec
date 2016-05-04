# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'casted_hash'

Gem::Specification.new do |spec|
  spec.name          = "casted_hash"
  spec.version       = CastedHash::VERSION
  spec.authors       = ["Stephan Kaag"]
  spec.email         = ["stephan@ka.ag"]
  spec.description = spec.summary = "A casted hash"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "mocha"
end
