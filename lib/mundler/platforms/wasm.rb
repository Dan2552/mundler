module WASMPlatform
  def self.config(options, build_config)
    cc_command = "emcc"
    linker_command = "emcc"
    archiver_command = "emar"

    cc_flags = ["-Os"]

    <<~BUILD
      MRuby::CrossBuild.new("wasm") do |conf|
        toolchain :clang

        #{build_config.gemboxes}
        #{build_config.gems}

        conf.cc do |cc|
          cc.command = #{cc_command.inspect}
          cc.flags = #{cc_flags.inspect}
        end

        conf.linker do |l|
          l.command = #{linker_command.inspect}
        end

        conf.archiver do |a|
          a.command = #{archiver_command.inspect}
        end
      end
    BUILD
  end
end

define_platform "wasm", WASMPlatform
