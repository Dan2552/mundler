module IOSPlatform
  def self.config(options, build_config)
    valid_archs = [:armv7, :arm64]
    default_archs = [:arm64]
    options[:archs] ||= default_archs

    options[:archs].map do |arch|
      unless valid_archs.include?(arch)
        raise "Invalid architecture #{arch}. Valid values: #{valid_archs}"
      end

      minimum_ios_version = options[:minimum_ios_sdk_version] || "10.0"
      ios_sdk = `xcrun --sdk iphoneos --show-sdk-path`.chomp

      clang = `xcrun -find clang`.chomp
      flags = %W(
        -O3
        -miphoneos-version-min=#{minimum_ios_version}
        -arch #{arch}
        -isysroot #{ios_sdk}
      )

      cc_command = options.dig(:cc, :command) || clang
      linker_command = options.dig(:linker, :command) || clang

      cc_flags = flags + Array(options.dig(:cc, :flags) || [])
      linker_flags = flags + Array(options.dig(:linker, :flags) || [])

      <<~BUILD
        MRuby::CrossBuild.new("ios__#{arch}") do |conf|
          #{build_config.gemboxes}
          #{build_config.gems(:ios)}

          conf.cc do |cc|
            cc.command = #{cc_command.inspect}
            cc.flags = #{cc_flags.inspect}
          end

          conf.linker do |l|
            l.command = #{linker_command.inspect}
            l.flags = #{linker_flags.inspect}
          end
        end
      BUILD
    end.join("\n")
  end
end

define_platform "ios", IOSPlatform
