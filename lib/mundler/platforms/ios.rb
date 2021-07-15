module IOSPlatform
  def self.config(options, build_config)
    valid_archs = [:armv7, :arm64]
    options[:archs] ||= valid_archs

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

      <<~BUILD
        MRuby::CrossBuild.new("ios__#{arch}") do |conf|
          #{build_config.gemboxes}
          #{build_config.gems}

          conf.cc do |cc|
            cc.command = #{clang.inspect}
            cc.flags = #{flags.inspect}
          end

          conf.linker do |l|
            l.command = #{clang.inspect}
            l.flags = #{flags.inspect}
          end
        end
      BUILD
    end.join("\n")
  end
end

define_platform "ios", IOSPlatform
