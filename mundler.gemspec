Gem::Specification.new do |spec|
  root = File.expand_path('..', __FILE__)
  require File.join(root, "lib", "mundler", "version.rb").to_s
  require "pathname"

  spec.name          = "mundler"
  spec.version       = Mundler::VERSION
  spec.authors       = ["Daniel Inkpen"]
  spec.email         = ["dan2552@gmail.com"]

  spec.summary       = %q{A simple tool help download and compile mruby when gems change}
  spec.description   = %q{A simple tool help download and compile mruby when gems change}
  spec.homepage      = "https://github.com/Dan2552/mundler"
  spec.license       = "MIT"

  spec.files = Dir
    .glob(File.join(root, "**", "*.rb"))
    .reject { |f| f.match(%r{^(test|spec|features)/}) }
    .map { |f| Pathname.new(f).relative_path_from(root).to_s }

  spec.files << "lib/mundler/cached_git/cached_git"
  spec.files << "lib/mundler/cached_git/git"

  if File.directory?(File.join(root, "exe"))
    spec.bindir = "exe"
    spec.executables = Dir.glob(File.join(root, "exe", "*"))
      .map { |f| File.basename(f) }
  end

  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"

  spec.add_dependency "thor"
  spec.add_dependency "rake"
end
