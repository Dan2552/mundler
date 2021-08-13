module Mundler
  class DSL
    def initialize(path)
      @config = Config.new
      @path = path

      load_libraries
      load_platforms
    end

    def evaluate!
      begin
        instance_eval(File.read(@path), @path)
      rescue Errno::ENOENT
        raise MundlefileNotFound
      end
    end

    attr_reader :config

    def load_libraries
      libraries = Dir.glob(File.join(__dir__, "libraries", "*.rb"))
      libraries.each do |library|
        instance_eval(File.read(library))
      end
    end

    def load_platforms
      platforms = Dir.glob(File.join(__dir__, "platforms", "*.rb"))
      platforms.each do |platform|
        instance_eval(File.read(platform))
      end
    end

    private

    def mruby(url: nil, tag: nil, branch: nil)
      branch = "stable" if tag.nil? && branch.nil?
      config.mruby[:url] = url if url
      config.mruby[:branch] = branch if branch
      config.mruby[:tag] = tag if tag
    end

    def gembox(name)
      config.gemboxes << name.to_s
    end

    def define_platform(name, platform_class)
      config.platform_types[name.to_s] = platform_class
    end

    def platform(name, options = {})
      config.platforms << { name: name.to_s, options: options }
    end

    def gem(name, core: nil, path: nil, github: nil)
      if path && !path.start_with?("/")
        app_path = Pathname.new(@path).dirname.to_s
        path = File.expand_path(File.join(app_path, path))
      end

      config.gems << { name: name, path: path, github: github, core: core }
    end

    def env(name, value)
      config.env[name] = value
    end

    def library(name, options = {})
      config.libraries[name.to_s] = options
    end

    def define_library(name, library_class)
      config.library_types[name.to_s] = library_class
    end
  end
end
