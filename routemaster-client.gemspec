# coding: utf-8
lib = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'routemaster/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'routemaster-client'
  spec.version       = Routemaster::Client::VERSION
  spec.authors       = ['Julien Letessier']
  spec.email         = ['julien.letessier@gmail.com']
  spec.summary       = %q{Client API for the Routemaster event bus}
  spec.homepage      = 'http://github.com/deliveroo/routemaster-client'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %w(.)

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_runtime_dependency     'typhoeus', '~> 1.1'
  spec.add_runtime_dependency     'faraday', '>= 0.9.0'
  spec.add_runtime_dependency     'wisper', '~> 1.6.1'
  spec.add_runtime_dependency     'oj', '>= 2.17'
  spec.add_runtime_dependency     'hashie'
end
