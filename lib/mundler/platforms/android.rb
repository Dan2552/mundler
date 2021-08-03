module AndroidPlatform
  def self.config(options, build_config)
    valid_archs = [:"arm64-v8a", :armeabi, :"armeabi-v7a"]
    options[:archs] ||= valid_archs

    options[:archs].map do |arch|
      unless valid_archs.include?(arch)
        raise "Invalid architecture #{arch}. Valid values: #{valid_archs}"
      end

      <<~BUILD
        MRuby::CrossBuild.new("android__#{arch}") do |conf|
          params = {
            :arch => #{arch.inspect},
            :platform => 'android-24',
            :toolchain => :clang,
          }

          if #{arch.inspect} == :"armeabi-v7a"
            params[:mfpu] = "neon"
            params[:mfloat_abi] = "hard"
          end

          toolchain :android, params

        #{cc_and_linker(options[:options])}
          #{build_config.gemboxes}
          #{build_config.gems}
        end
      BUILD
    end.join("\n")
  end

  def self.cc_and_linker(options)
    build = ""
    if options[:cc]
      build += "  conf.cc do |cc|\n"
      build += "    cc.command = #{options[:cc][:command].inspect}\n" if options[:cc][:command]
      build += "    cc.flags << #{options[:cc][:flags].inspect}\n" if options[:cc][:flags]
      build += "  end\n\n"
    end

    if options[:linker]
      build += "  conf.linker do |linker|\n"
      build += "    linker.command = #{options[:linker][:command].inspect}\n" if options[:linker][:command]
      build += "    linker.flags << #{options[:linker][:flags].inspect}\n" if options[:linker][:flags]
      build += "  end\n\n"
    end

    build
  end
end

define_platform "android", AndroidPlatform
