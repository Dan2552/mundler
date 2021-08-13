require "thor"

module Mundler
  class CLI < Thor
    include Thor::Actions

    def self.exit_on_failure?
      true
    end

    desc "install", "Download and compile mruby"
    def install
      Mundler::Project.new(Dir.pwd).install
      puts("\e[32mMundle complete!\e[0m")
    rescue Mundler::CompilationError
      $stderr.puts("\e[31mMundle failed\e[0m")
      exit 1
    rescue Interrupt
      $stderr.puts("\e[31mMundle failed (user cancelled)\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    desc "update", "Same as install except it forces recompile"
    def update
      project = Mundler::Project.new(Dir.pwd)
      project.clean
      project.install
    rescue Mundler::CompilationError
      $stderr.puts("\e[31mFailed to install\e[0m")
      exit 1
    rescue Interrupt
      $stderr.puts("\e[31mUser cancelled\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    desc "summary", "Print a summary of installed libraries and binaries"
    def summary
      project = Mundler::Project.new(Dir.pwd)
      project.print_summary
    rescue Interrupt
      $stderr.puts("\e[31mUser cancelled\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    desc "clean", "Removes cached versions of mruby."
    def clean
      Mundler::Project.new(Dir.pwd).clean
    rescue Interrupt
      $stderr.puts("\e[31mUser cancelled\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    desc "exec", "Execute command with mruby's bin prepended to $PATH"
    def exec(*args)
      Mundler::Project.new(Dir.pwd).exec(args)
    rescue Interrupt
      exit 1
    rescue NotInstalledError
      $stderr.puts("\e[31mChanges to the Mundlefile have been detected. Run `mundle install` and try again.\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    desc "path", "Prints out the path relevant to the compiled version of mruby relevant to the `Mundlefile`"
    def path
      puts Mundler::Project.new(Dir.pwd).path
    rescue Interrupt
      $stderr.puts("\e[31mUser cancelled\e[0m")
      exit 1
    rescue MundlefileNotFound
      $stderr.puts("\e[31mMundlefile not found in the current directory\e[0m")
      exit 1
    end

    default_task :install
  end
end
