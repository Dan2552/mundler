MRuby::Build.new do |conf|
  toolchain :clang

  {{ contents }}
end

if `which xcrun`.chomp.strip.length > 0
  min_ver = ENV['MINIMUM_IOS_SDK_VERSION'] || "10.0"
  clang_path = `xcrun -find clang`.chomp
  ios_sdk = `xcrun --sdk iphoneos --show-sdk-path`.chomp
  ios_simulator_sdk = `xcrun --sdk iphonesimulator --show-sdk-path`.chomp
  base_flags = ["-O3", "-mios-simulator-version-min=#{min_ver}"]
  ios_flags = base_flags + %W(-arch armv7 -arch arm64 -isysroot #{ios_sdk})
  ios_simulator_flags = base_flags + %W(-arch i386 -arch x86_64 -isysroot #{ios_simulator_sdk})

  # MRuby::CrossBuild.new('ios') do |conf|
  #    contents

  #   conf.cc do |cc|
  #     cc.command = clang_path
  #     cc.flags = ios_flags
  #   end

  #   conf.linker do |l|
  #     l.command = clang_path
  #     l.flags = ios_flags
  #   end
  # end

  # MRuby::CrossBuild.new('ios-simulator') do |conf|
  #   contents

  #   conf.cc do |cc|
  #     cc.command = clang_path
  #     cc.flags = ios_simulator_flags
  #   end

  #   conf.linker do |l|
  #     l.command = clang_path
  #     l.flags = ios_simulator_flags
  #   end
  # end
end
