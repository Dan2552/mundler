require "mundler/version"
require "tempfile"
require "digest"

module Mundler
  def self.install(force: false)
    unless needs_reinstall? || force
      puts "Nothing to do."
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

    # Download mruby if it doesn't exist locally
    unless File.directory?(File.join(mundler_root, hex))
      system("git clone https://github.com/#{repo}.git #{hex}") ||
        error_out("Failed to clone mruby")
    end

    FileUtils.cd(File.join(mundler_root, hex))

    system("git fetch") ||
      error_out("Failed to git fetch")

    system("git reset --hard #{version}") ||
      error_out("Failed to set version to #{version}")

    config_file = Tempfile.new("mundler")

    build_config = File.read(File.join(__dir__, "mundler", "build_config.rb"))
    build_config.gsub!("{{ contents }}", contents)

    rake = `which rake`.chomp

    tempfile = Tempfile.new(['mundler_config', '.rb'])
    begin
      File.write(tempfile, build_config)

      system(
        { "MRUBY_CONFIG" => tempfile.path },
        "#{rake} clean && #{rake} deep_clean && #{rake}"
      ) || error_out("Failed to compile.")
    ensure
      tempfile.close
      tempfile.delete
    end

    FileUtils.cd(project_directory)

    save_lock
  end

  def self.clean
    return unless File.directory?(File.join(ENV["HOME"], ".mundler"))

    FileUtils.remove_dir(File.join(ENV["HOME"], ".mundler"))
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
      Digest::MD5.hexdigest(contents)
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

    system({ "PATH" => path }, *args)
  end

  def self.path
    puts File.join(ENV["HOME"], ".mundler", hex)
  end
end
