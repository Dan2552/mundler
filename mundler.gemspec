
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mundler/version"

Gem::Specification.new do |spec|
  spec.name          = "mundler"
  spec.version       = Mundler::VERSION
  spec.authors       = ["Daniel Inkpen"]
  spec.email         = ["dan2552@gmail.com"]

  spec.summary       = %q{A simple tool help download and compile mruby when gems change}
  spec.description   = %q{A simple tool help download and compile mruby when gems change}
  spec.homepage      = "https://github.com/Dan2552/mundler"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake"

  spec.add_dependency "thor", "~> 0.20.3"
  spec.add_dependency "rake"
end
