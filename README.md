# Mundler

A simple tool help download and compile mruby when gems in your project change, automatically keeping track on whether a recompile is necessary or not.

Inspired by the ease-of-use of bundler, but certainly not the equivalent. This gem itself doesn't deal with dependency management or downloading the gems itself as mruby itself handles that all perfectly well.

## Installation

Run:

    $ gem install mundler

## Usage

Put a `Mundlefile` at the root of your project and run `mundle install` (or just `mundle`). A `Mundlefile.lock` will be generated with the format of mruby's `build_config.rb`. The install will use this config to configure the compilation of mruby.

A `Mundlefile` declares desired gems. For example:

``` ruby
mruby tag: "3.0.0"

platform "ios", archs: [:armv7, :arm64]
platform "ios_simulator", archs: [:i386, :x86_64]

gembox "default"
gem "mruby-regexp-pcre"
gem "mruby-iijson"
gem "mruby-secure-random"
gem "mruby-eval", core: "mruby-eval"
```

Cached (source and compiled) versions of mruby will sit under `~/.mundler`.

`mundle clean` will clean the mruby cache (of the mruby version applicable to the `Mundlefile`).

`mundle update` is the same as `mundle clean` and `mundle install`.

`mundle exec` execute a commands with mruby's bin prepended to $PATH (of the mruby version applicable to the `Mundlefile`)

`mundle path` prints out the path relevant to the compiled version of mruby relevant to the `Mundlefile`. This can be useful for using in compiler flags.

`mundle summary` will print a summary of the compiled binaries and libraries.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
