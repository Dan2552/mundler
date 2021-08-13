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

    def platform(platform_attrs)
      platform_name = platform_attrs[:name].to_s
      type = @config.platform_types[platform_name]
      raise "Can't find platform: #{platform_name}" unless type

      options = {}
      @config.libraries.each do |library_name, library_options|
        library_type = @config.library_types[library_name]

        raise "Unknown library: #{library_name}" unless library_type

        library_builder = library_type.new

        puts "Using #{library_name} library (#{platform_name})"
        library_builder.build(platform_name, library_options)
        library_attrs = library_builder.platform_configuration(platform_name, library_options)

        merge_platform_attributes!(options, library_attrs)
      end

      merge_platform_attributes!(options, platform_attrs[:options])

      type.config(platform_attrs.merge(options: options), self)
    end

    # Merge with a bit of specific logic to make sure build settings
    #
    # E.g. if lhs was something like
    #
    # ```
    # {
    #   cc: { flags: "-I#{sdl_install}/include/SDL2" },
    #   linker: { flags: "-L#{sdl_install}/lib -lSDL2 -lSDL2_image -lSDL2_ttf" }
    # }
    # ```
    #
    # and rhs was like
    #
    # ```
    # {
    #   cc: { flags: "abc" },
    #   linker: { flags: "def" },
    #   more_options: true
    # }
    # ```
    #
    # result would be
    # ```
    # {
    #   cc: { flags: ["-I#{sdl_install}/include/SDL2", "abc"] },
    #   linker: { flags: ["-L#{sdl_install}/lib -lSDL2 -lSDL2_image -lSDL2_ttf", "def"] }
    #   more_options: true
    # }
    # ```
    #
    def merge_platform_attributes!(lhs, rhs)
      rhs = rhs.dup

      [:cc, :linker].each do |cc_or_linker|
        [:command, :flags].each do |command_or_flags|
          lhs_flags = lhs.dig(cc_or_linker, command_or_flags)
          rhs_flags = rhs.dig(cc_or_linker, command_or_flags)

          if rhs_flags
            lhs[cc_or_linker] ||= {}
            lhs[cc_or_linker][command_or_flags] ||= []
            lhs_flags = lhs.dig(cc_or_linker, command_or_flags)

            if lhs_flags.is_a?(String)
              lhs[cc_or_linker][command_or_flags] = [lhs_flags]
            end

            if rhs_flags.is_a?(String)
              rhs[cc_or_linker][command_or_flags] = [rhs_flags]
            end

            lhs[cc_or_linker][command_or_flags] = lhs[cc_or_linker][command_or_flags] + rhs[cc_or_linker][command_or_flags]
          end
        end

        rhs.delete(cc_or_linker)
      end

      lhs.merge!(rhs)
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
