require "mundler/version"
require "tempfile"
require "digest"
require "pathname"

module Mundler
  def self.install(force: false)
    unless needs_reinstall? || force
      puts "Nothing to do."
      summary
      return
    end

    # Calculate hex early to cache result incase file changes as it's going
    hex

    project_directory = Dir.pwd

    repo, version, contents = read_mundlefile

    mundler_root = File.join(ENV["HOME"], ".mundler")

    # Create cache directory if it doesn't exist
    Dir.mkdir(mundler_root) unless File.directory?(mundler_root)

    FileUtils.cd(mundler_root)

    cache_root = File.join(mundler_root, "cache")

    repo_org, repo_name = repo.split("/")

    # Download mruby if it doesn't exist locally
    unless File.directory?(File.join(cache_root, repo_org, repo_name))
      FileUtils.mkdir_p(File.join(cache_root, repo_org))
      FileUtils.cd(File.join(cache_root, repo_org))
      system("git clone https://github.com/#{repo}.git #{repo_name} >/dev/null 2>&1") ||
        error_out("Failed to clone mruby: #{repo}")
    end

    unless File.directory?(File.join(mundler_root, hex))
      FileUtils.cp_r(
        File.join(cache_root, repo_org, repo_name),
        File.join(mundler_root, hex)
      )
    end

    FileUtils.cd(File.join(mundler_root, hex))

    system("git fetch >/dev/null 2>&1") ||
      error_out("Failed to git fetch")
    system("git reset --hard #{version} >/dev/null 2>&1") ||
      error_out("Failed to set version to #{version}")

    config_file = Tempfile.new("mundler")

    build_config = File.read(File.join(__dir__, "mundler", "build_config.rb"))
    build_config.gsub!("{{ contents }}", contents)

    rake = `which rake`.chomp

    tempfile = Tempfile.new(['mundler_config', '.rb'])
    logfile = Tempfile.new(['mundler_build', '.log'])
    begin
      File.write(tempfile, build_config)

      covered = []

      log_thread = Thread.new do
        loop do
          Dir.glob(File.join(Dir.pwd, "build", "*", "*", "*")).each do |file|
            pathname = Pathname.new(file)
            directory = pathname.directory? ? pathname.to_s : Pathname.new(file).dirname.to_s
            next if covered.include?(directory)
            covered << directory

            print "\e[32m.\e[0m"
          end
          sleep 0.3
        end
      end

      dir = __dir__
      cached_git_dir = File.expand_path(File.join(dir, "..", "cached_git"))

      compile = Proc.new do
        system(
          {
            "MRUBY_CONFIG" => tempfile.path,
            "PATH" => ([cached_git_dir] + ENV["PATH"].split(":")).join(":")
          },
          "#{rake} deep_clean >#{logfile.path} 2>&1 && #{rake} >#{logfile.path} 2>&1"
        ) || begin
          puts File.read(logfile)
          error_out("Failed to compile.")
        end
      end

      if defined?(Bundler) && Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env(&compile)
      elsif defined?(Bundler)
        Bundler.with_clean_env(&compile)
      else
        compile.call
      end

      log_thread.kill
      puts "\n\nSuccessfully compiled mruby."
      summary
    rescue Interrupt
      FileUtils.rm_rf(File.join(mundler_root, hex))
      exit(1)
    ensure
      tempfile.close
      tempfile.delete
      logfile.close
      logfile.delete
    end

    FileUtils.cd(project_directory)

    save_lock
  end

  def self.clean
    mundler_root = File.join(ENV["HOME"], ".mundler")
    return unless File.directory?(File.join(mundler_root, hex))
    FileUtils.rm_rf(File.join(mundler_root, hex))
  end

  def self.read_mundlefile
    contents = File.read(File.join(Dir.pwd, "Mundlefile"))

    first_line = contents.split("\n").first

    unless first_line.strip.start_with?("#")
      return ["mruby/mruby", "stable", contents]
    end

    repo, version = first_line.split("#", 2).last.strip.split(" ", 2)

    [repo, version, contents]
  end

  def self.needs_reinstall?
    return true unless File.file?(File.join(Dir.pwd, "Mundlefile.lock"))

    old_hex = File.read(File.join(Dir.pwd, "Mundlefile.lock")).chomp

    old_hex != hex ||
      !File.file?(File.join(ENV["HOME"], ".mundler", hex, ".mundler_build_complete"))
  end

  def self.hex
    @hex ||= begin
      contents = File.read(File.join(Dir.pwd, "Mundlefile"))
      build_config = File.read(File.join(__dir__, "mundler", "build_config.rb"))
      build_config.gsub!("{{ contents }}", contents)
      Digest::MD5.hexdigest(build_config)
    end
  end

  def self.save_lock
    File.write(File.join(Dir.pwd, "Mundlefile.lock"), hex)
    File.write(File.join(ENV["HOME"], ".mundler", hex, ".mundler_build_complete"), hex)
  end

  def self.error_out(message)
    STDERR.puts(message)
    exit(1)
  end

  def self.exec(args)
    if needs_reinstall?
      error_out("Changes to the Mundlefile have been detected. Run `mundle install` and try again.")
    end

    bin_dir = File.join(ENV["HOME"], ".mundler", hex, "bin")
    path = bin_dir + ":" + ENV['PATH']

    Process.spawn({ "PATH" => path }, *args)
    Process.wait
    exit($?.exitstatus) if $?.exitstatus
  rescue Interrupt
  end

  def self.path
    puts File.join(ENV["HOME"], ".mundler", hex)
  end

  def self.summary
    mundler_root = File.join(ENV["HOME"], ".mundler")
    FileUtils.cd(File.join(mundler_root, hex))
    puts ""
    puts "Libraries:"
    Dir.glob(File.join(Dir.pwd, "**", "*.a")).each { |a| puts "* " + a.split("build/").last }

    binaries = Dir.glob(File.join(Dir.pwd, "build", "host", "bin", "*"))
    if binaries.count > 0
      puts ""
      puts "Binaries:"
      binaries.each { |a| puts "* " + a.split("/").last }
    end
  end
end
