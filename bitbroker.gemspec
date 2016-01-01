# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitbroker/version'

Gem::Specification.new do |spec|
  spec.name          = "bitbroker"
  spec.version       = Bitbroker::VERSION
  spec.authors       = ["Hiroyasu OHYAMA"]
  spec.email         = ["user.localhost2000@gmail.com"]

  spec.summary       = %q{File Synchronize Software}
  spec.description   = %q{Yet another File Synchronize Software using AMQP}
  spec.homepage      = "https://github.com/userlocalhost2000/bitbroker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "msgpack", "0.7.1"
  spec.add_runtime_dependency "turnip", "2.0.1"
  spec.add_runtime_dependency "listen", "3.0.5"
  spec.add_runtime_dependency "bunny", "2.2.1"
  spec.add_runtime_dependency "macaddr", "1.7.1"
end
