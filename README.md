# Mundler

A simple tool help download and compile mruby when gems in your project change, keeping track on whether a recompile is necessary or not.

Inspired by the ease-of-use of bundler, but certainly not the equivalent. This gem itself doesn't deal with dependency management or downloading the gems itself as mruby itself handles that all perfectly well.

There may even be tooling that exists already like this for this exact purpose that I'm just not aware of, but it's a quick thing to make / low maintainence, so no harm either way. For simplicity sake some assumptions are made, so this probably isn't for everyone.

## Installation

Install it yourself as:

    $ gem install mundler

## Usage

Put a `Mundlefile` at the root of your project and run `mundle install` (or just `mundle`). A `Mundlefile.lock` will be created to keep track whether running `mundle` again should recompile mruby.

The `Mundlefile` should use the same syntax to the `build_config.rb`. For example:

``` ruby
# mruby/mruby 57a56dd

conf.gembox 'default'

conf.gem :mgem => 'mruby-regexp-pcre'
conf.gem :mgem => 'mruby-iijson'
conf.gem :mgem => 'mruby-secure-random'
conf.gem :core => 'mruby-eval'
```

Notably the *first line in the file* can be a comment that dictates which github repo to clone mruby from, and what git commit hash to use. If this line is missing, it will default to `mruby/mruby stable`.

Cached compiled versions of mruby will sit under `~/.mundler`.

`mundle clean` will remove all cached versions of mruby.

`mundle update` is the same as `mundle install` except will replace previous cached copies.

`mundle exec` execute a commands with mruby's bin prepended to $PATH (of the mruby version applicable to the `Mundlefile`)

`mundle path` prints out the path relevant to the compiled version of mruby relevant to the `Mundlefile`. This can be useful for using in compiler flags.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
