lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "twib/version"

Gem::Specification.new do |spec|
  spec.name          = "twib"
  spec.version       = Twib::VERSION
  spec.authors       = ["misson20000"]
  spec.email         = ["xenotoad@xenotoad.net"]

  spec.summary       = "Twili bridge client for Ruby"
  spec.homepage      = "https://github.com/misson20000/ruby-twib/"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.license       = 'ISC'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "msgpack"
end
