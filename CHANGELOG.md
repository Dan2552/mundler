# 0.9.0

* Web assembly support (wasm)
* Allow individual gems to specify target platform(s)
* Fix implicit "stable" mruby
* Fix error messaging when the target mruby version isn't available

# 0.8.0

* Basic "libraries" support
* General text output improvements
* Fixes for optional platform options

# 0.7.0

* Fix gems with relative paths
* Adds "host" as a special platform to allow mruby's host platform cc and linker commands/flags to be customised
* Allow iOS and Android cc and linker commands/flags to be customised
* Allow env vars to be set in the Mundlefile DSL
* Prints build config when builds fail to help debugging

# 0.6.1

* Adds cached_git to source files

# 0.6.0

* Add android as a built-in platform
* Fix issue where gemspec was pointing to absolute paths (github issue #1)

# 0.5.0

* First rubygems release
