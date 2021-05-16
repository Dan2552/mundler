begin
  DEFAULT_PLATFORMS = {
    :ios => [:armv7, :arm64],
    :ios_simulator => [:i386, :x86_64],
    :macos => [:x86_64, :arm64]
  }.freeze

  def only_host_platform!
    @platforms = {}
  end

  def clang_path(set = nil)
    @clang_path = set if set
    @clang_path || clang_path = `xcrun -find clang`.chomp
  end

  def ios_sdk(set = nil)
    @ios_sdk = set if set
    @ios_sdk || `xcrun --sdk iphoneos --show-sdk-path`.chomp
  end

  def ios_simulator_sdk(set = nil)
    @ios_simulator_sdk = set if set
    @ios_simulator_sdk || `xcrun --sdk iphonesimulator --show-sdk-path`.chomp
  end

  def macos_sdk(set = nil)
    @macos_sdk = set if set
    @macos_sdk || `xcrun --sdk macosx --show-sdk-path`.chomp
  end

  def minimum_ios_version(set = nil)
    @minimum_ios_version = set if set
    @minimum_ios_version || ENV['MINIMUM_IOS_SDK_VERSION'] || "10.0"
  end

  PLATFORM_FLAGS = {
    ios: -> (arch) { %W(-O3 -miphoneos-version-min=#{minimum_ios_version} -arch #{arch} -isysroot #{ios_sdk}) },
    ios_simulator: -> (arch) { %W(-O3 -mios-simulator-version-min=#{minimum_ios_version} -arch #{arch} -isysroot #{ios_simulator_sdk}) },
    macos: -> (arch) { %W(-O3 -arch #{arch} -isysroot #{macos_sdk}) }
  }

  PLATFORM_COMMAND = {
    ios: clang_path,
    ios_simulator: clang_path,
    macos: clang_path
  }

  def platform(name, architectures)
    @platforms ||= {}
    @platforms[name] = Array(architectures)
  end

  def platforms
    @platforms&.dup&.freeze || DEFAULT_PLATFORMS
  end

  def host_is_macos?
    `which xcrun`.chomp.strip.length > 0
  end

  class FakeConfig
    def gem(*args); end
    def enable_test(*args); end
    def gembox(*args); end
    def enable_debug(*args); end
    def enable_bintest(*args); end
  end

  conf = FakeConfig.new

  FileUtils.cd(Pathname.new(ENV["MUNDLEFILE"]).dirname)

  {{ contents }}

  if host_is_macos?
    if `xcrun --sdk macosx --show-sdk-path 2>&1`.include?("cannot be located")
      system("xcrun --sdk macosx --show-sdk-path")
      puts ""
      puts "Check your Xcode installation"
      exit 1
    end
  end

  if host_is_macos?
    MRuby::Build.new do |conf|
      toolchain :clang

      FileUtils.cd(Pathname.new(ENV["MUNDLEFILE"]).dirname)
      {{ contents }}

      this_arch = `uname -m`.chomp

      command = PLATFORM_COMMAND[:macos]
      flags = PLATFORM_FLAGS[:macos]
      command = command.call(this_arch) if command.respond_to?(:call)
      flags = flags.call(this_arch) if flags.respond_to?(:call)

      conf.cc do |cc|
        cc.command = command
        cc.flags = flags
      end

      conf.linker do |l|
        l.command = command
        l.flags = flags
      end
    end
  else
    MRuby::Build.new do |conf|
      toolchain :clang

      FileUtils.cd(Pathname.new(ENV["MUNDLEFILE"]).dirname)
      {{ contents }}
    end
  end

  platforms.each do |platform_name, architectures|
    architectures.each do |arch|
      MRuby::CrossBuild.new("#{platform_name}__#{arch}") do |conf|
        FileUtils.cd(Pathname.new(ENV["MUNDLEFILE"]).dirname)
        {{ contents }}

        command = PLATFORM_COMMAND[platform_name]
        flags = PLATFORM_FLAGS[platform_name]
        command = command.call(arch) if command.respond_to?(:call)
        flags = flags.call(arch) if flags.respond_to?(:call)

        conf.cc do |cc|
          cc.command = command
          cc.flags = flags
        end

        conf.linker do |l|
          l.command = command
          l.flags = flags
        end
      end
    end
  end
rescue Exception => e
  puts e.inspect
  puts e.backtrace
  exit 1
end
