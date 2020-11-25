if `which xcrun`.chomp.strip.length > 0 && `uname -a`.chomp.include?("arm64")
  if `xcrun --sdk macosx --show-sdk-path 2>&1`.include?("cannot be located")
    system("xcrun --sdk macosx --show-sdk-path")
    puts ""
    puts "Check your Xcode installation"
    exit 1
  end

  MRuby::Build.new do |conf|
    toolchain :clang

    {{ contents }}

    clang_path = `xcrun -find clang`.chomp
    macos_sdk = `xcrun --sdk macosx --show-sdk-path`.chomp
    macos_flags = %W(-O3 -arch arm64 -isysroot #{macos_sdk})

    conf.cc do |cc|
      cc.command = clang_path
      cc.flags = macos_flags
    end

    conf.linker do |l|
      l.command = clang_path
      l.flags = macos_flags
    end
  end
else
  MRuby::Build.new do |conf|
    toolchain :clang

    {{ contents }}
  end
end

if `which xcrun`.chomp.strip.length > 0
  if `xcrun --sdk iphoneos --show-sdk-path 2>&1`.include?("cannot be located")
    system("xcrun --sdk iphoneos --show-sdk-path")
    puts ""
    puts "Check your Xcode installation"
    exit 1
  end

  min_ver = ENV['MINIMUM_IOS_SDK_VERSION'] || "10.0"
  clang_path = `xcrun -find clang`.chomp
  ios_sdk = `xcrun --sdk iphoneos --show-sdk-path`.chomp
  ios_simulator_sdk = `xcrun --sdk iphonesimulator --show-sdk-path`.chomp
  ios_flags = %W(-O3 -miphoneos-version-min=#{min_ver} -arch armv7 -arch arm64 -isysroot #{ios_sdk})
  ios_simulator_flags = %W(-O3 -mios-simulator-version-min=#{min_ver} -arch i386 -arch x86_64 -isysroot #{ios_simulator_sdk})

  MRuby::CrossBuild.new('ios') do |conf|
    {{ contents }}

    conf.cc do |cc|
      cc.command = clang_path
      cc.flags = ios_flags
    end

    conf.linker do |l|
      l.command = clang_path
      l.flags = ios_flags
    end
  end

  MRuby::CrossBuild.new('ios-simulator') do |conf|
    {{ contents }}

    conf.cc do |cc|
      cc.command = clang_path
      cc.flags = ios_simulator_flags
    end

    conf.linker do |l|
      l.command = clang_path
      l.flags = ios_simulator_flags
    end
  end
end
