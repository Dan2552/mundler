module Mundler
  class BuildConfig
    def initialize(config)
      @config = config
    end

    def tempfile
      tempfile = Tempfile.new("build_config.rb")
      File.write(tempfile, contents)
      tempfile
    end

    def gemboxes
      @config.gemboxes.map do |gembox|
        "conf.gembox #{gembox.inspect}"
      end.join("\n")
    end

    def gems
      @config.gems.map do |gem|
        # e.g. gem = {:name=>"mruby-regexp-pcre", :path=>nil, :github=>nil, :core=>nil}
        args = ":mgem => #{gem[:name].inspect}"

        if gem[:github]
          args = ":github => #{gem[:github].inspect}"
        elsif gem[:path]
          args = ":path => #{gem[:path].inspect}"
        elsif gem[:core]
          args = ":core => #{gem[:core].inspect}"
        end

        "conf.gem #{args}"
      end.join("\n  ")
    end

    def mruby_version
      mruby_url = @config.mruby[:url]

      version = (
        @config.mruby[:tag] ||
        @config.mruby[:branch] ||
        @config.mruby[:version]
      )

      "#{mruby_url} #{version}"
    end

    private

    def platforms
      @config.platforms.map do |platform|
        type = @config.platform_types[platform[:name].to_s]
        raise "Can't find platform: #{platform[:name]}" unless type
        type.config(platform, self)
      end.join("\n")
    end

    def env_vars
      str = ""
      @config.env.each do |key, value|
        str = str + "\nENV[\"#{key}\"] = \"#{value}\""
      end
      str
    end

    def contents
      contents = <<~CONTENTS
        # #{mruby_version}
        #{env_vars}

        MRuby::Build.new do |conf|
          toolchain :clang

          #{gemboxes}
          #{gems}
        end

        #{platforms}
      CONTENTS

      contents.strip + "\n"
    end
  end
end
