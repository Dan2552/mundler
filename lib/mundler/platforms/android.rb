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

          #{build_config.gemboxes}
          #{build_config.gems}
        end
      BUILD
    end.join("\n")
  end
end

define_platform "android", AndroidPlatform
