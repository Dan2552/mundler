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

      Mundler.with_clean_env do
        system(
          {
            # The {mundler gem path}/cached_git directory contains a binary called
            # `git` that will run instead of normal git, making a cache of a
            # clone.
            "PATH" => ([cached_git_dir] + ENV["PATH"].split(":")).join(":")
          },
          "git clone #{mruby_url} . >/dev/null 2>&1"
        ) || raise(Mundler::CloneError, "Failed to clone #{mruby_url}")
      end

      if version
        system("git reset --hard #{version} >/dev/null 2>&1") ||
          system("git reset --hard origin/#{version} >/dev/null 2>&1") ||
          exit_out("Failed to set mruby version to \"#{version}\".")
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

      version = (
        @config.mruby[:tag] ||
        @config.mruby[:branch] ||
        @config.mruby[:version]
      )

      @config.gemboxes.each do |gembox|
        puts "Using #{gembox} gembox"
      end
      @config.gems.each do |gem|
        puts "Using #{gem[:name]} gem"
      end

      puts "Using mruby (#{version})"


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
              print "\e[34m.\e[0m"
            end
          end
          sleep(0.3)
        end
      end

      Mundler.with_clean_env do
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
          $stderr.puts File.read(build_config)
          $stderr.puts File.read(logfile)

          raise Mundler::CompilationError
        end

        cleaned = true

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
          $stderr.puts File.read(build_config)
          $stderr.puts File.read(logfile)

          raise Mundler::CompilationError
        end
      end

      puts "\n\n"

      FileUtils.touch(success_indicator)
    ensure
      output_thread.kill if output_thread
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

    def exit_out(msg)
      STDERR.puts("\e[31m#{msg}\e[0m")
      exit(1)
    end

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
