module Mundler
  class MRuby
    def initialize(config)
      @config = config
      @path = File.join(ENV["HOME"], ".mundler", config.hex)

      # Protect just incase, as we're doing an rm_rf
      raise "Something went wrong" if config.hex.length == 0
    end

    attr_reader :path

    def delete_repository
      FileUtils.rm_rf(@path)
    end

    def clone_repository
      success_indicator = File.join(@path, ".mundler_cloned_successfully")
      return if File.file?(success_indicator)

      mruby_url = @config.mruby[:url]

      version = (
        @config.mruby[:tag] ||
        @config.mruby[:branch] ||
        @config.mruby[:version]
      )

      FileUtils.rm_rf(@path)
      FileUtils.mkdir_p(@path)
      FileUtils.cd(@path)
      git_clone = Proc.new do
        system(
          {
            # The {mundler gem path}/cached_git directory contains a binary called
            # `git` that will run instead of normal git, making a cache of a
            # clone.
            "PATH" => ([cached_git_dir] + ENV["PATH"].split(":")).join(":")
          },
          "git clone #{mruby_url} . >/dev/null 2>&1"
        ) || error_out("Failed to clone mruby: #{mruby_url}")
      end

      if defined?(Bundler) && Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env(&git_clone)
      elsif defined?(Bundler)
        Bundler.with_clean_env(&git_clone)
      else
        git_clone.call
      end

      if version
        system("git reset --hard #{version} >/dev/null 2>&1") ||
          error_out("Failed to set version to #{version}")
      end

      FileUtils.touch(success_indicator)
    end

    def exec(args)
      raise NotInstalledError unless installed?

      bin_dir = File.join(@path, "bin")
      path = bin_dir + ":" + ENV['PATH']
      Process.spawn({ "PATH" => path }, *args)
      Process.wait
      exit($?.exitstatus) if $?.exitstatus
    end

    def compile(build_config)
      logfile = Tempfile.new(['mundler_build', '.log'])

      success_indicator = File.join(@path, ".mundler_built_successfully")
      if File.file?(success_indicator)
        return
      end

      FileUtils.cd(@path)

      cleaned = false
      covered = []
      output_thread = Thread.new do
        loop do
          if cleaned
            Dir.glob(File.join(Dir.pwd, "build", "*", "*", "*")).each do |file|
              pathname = Pathname.new(file)
              directory = pathname.directory? ? pathname.to_s : Pathname.new(file).dirname.to_s
              next if covered.include?(directory)
              covered << directory
              print "\e[32m.\e[0m"
            end
          end
          sleep(0.3)
        end
      end

      clean = Proc.new do
        rake = `which rake`.chomp
        system(
          {
            "MRUBY_CONFIG" => build_config,
            # The {mundler gem path}/cached_git directory contains a binary called
            # `git` that will run instead of normal git, making a cache of a
            # clone.
            "PATH" => ([cached_git_dir] + ENV["PATH"].split(":")).join(":")
          },
          "#{rake} clean >#{logfile.path} 2>&1 && #{rake} deep_clean >#{logfile.path} 2>&1"
        ) || begin
          $stderr.print "\e[31mF\e[0m"
          $stderr.puts "\n\n"
          $stderr.puts File.read(logfile)

          raise Mundler::CompilationError
        end

        cleaned = true
      end

      compile = Proc.new do
        rake = `which rake`.chomp
        system(
          {
            "MRUBY_CONFIG" => build_config,
            # The {mundler gem path}/cached_git directory contains a binary called
            # `git` that will run instead of normal git, making a cache of a
            # clone.
            "PATH" => ([cached_git_dir] + ENV["PATH"].split(":")).join(":")
          },
          "#{rake} >#{logfile.path} 2>&1"
        ) || begin
          $stderr.print "\e[31mF\e[0m"
          $stderr.puts "\n\n"
          $stderr.puts File.read(logfile)

          raise Mundler::CompilationError
        end
      end

      if defined?(Bundler) && Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env(&clean)
        Bundler.with_unbundled_env(&compile)
      elsif defined?(Bundler)
        Bundler.with_clean_env(&clean)
        Bundler.with_clean_env(&compile)
      else
        clean.call
        compile.call
      end

      output_thread.kill
      FileUtils.touch(success_indicator)
    ensure
      logfile.close
      logfile.delete
    end

    def print_summary
      FileUtils.cd(@path)
      puts "Libraries:"
      Dir.glob(File.join(Dir.pwd, "**", "*.a")).each { |a| puts "* " + a.split("build/").last }

      binaries = Dir.glob(File.join(Dir.pwd, "build", "host", "bin", "*"))
      if binaries.count > 0
        puts ""
        puts "Binaries:"
        binaries.each { |a| puts "* " + a.split("/").last }
      end
    end

    private

    def installed?
      success_indicator = File.join(@path, ".mundler_built_successfully")
      File.file?(success_indicator)
    end

    def cached_git_dir
      dir = File.expand_path(File.join(__dir__, "cached_git"))
      raise "cached git not found" unless File.file?(File.join(dir, "git"))
      raise "cached git not found" unless File.file?(File.join(dir, "cached_git"))
      dir
    end
  end
end
