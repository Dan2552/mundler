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

    def host_platform
      @config.platforms
        .select { |attributes| attributes[:name].to_s == "host" }
        .map { |attributes| platform(attributes) }
        .join("\n")
    end

    def non_host_platforms
      @config.platforms
        .select { |attributes| attributes[:name].to_s != "host" }
        .map { |attributes| platform(attributes) }
        .join("\n")
    end

    def platform(attributes)
      type = @config.platform_types[attributes[:name].to_s]
      raise "Can't find platform: #{attributes[:name]}" unless type
      type.config(attributes, self)
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

        #{host_platform}
          #{gemboxes}
          #{gems}
        end

        #{non_host_platforms}
      CONTENTS

      (contents.strip + "\n").gsub("\n\n\n", "\n\n")
    end
  end
end
