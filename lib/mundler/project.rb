module Mundler
  class Project
    def initialize(project_path)
      @project_path = project_path
      @mruby = MRuby.new(config)
    end

    def install(&blk)
      @mruby.clone_repository
      build_config = BuildConfig.new(config).tempfile
      @mruby.compile(build_config.path)
      FileUtils.cp(build_config.path, File.join(@project_path, "Mundlefile.lock"))
    ensure
      if build_config
        build_config.close
        build_config.delete
      end
    end

    def print_summary
      @mruby.print_summary
    end

    def clean
      @mruby.delete_repository
    end

    def exec(args)
      @mruby.exec(args)
    end

    def path
      @mruby.path
    end

    private

    def config
      @config ||= begin
        mundlefile_path = (
          ENV["MUNDLEFILE_PATH"] ||
          File.join(@project_path, "Mundlefile")
        )

        dsl = DSL.new(mundlefile_path)
        dsl.evaluate!
        dsl.config
      end
    end
  end
end
