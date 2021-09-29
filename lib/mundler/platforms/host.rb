module HostPlatform
  def self.config(options, build_config)
    build = ""

    if options[:cc]
      build += "  conf.cc do |cc|\n"
      build += "    cc.command = #{options[:cc][:command].inspect}\n" if options[:cc][:command]
      build += "    cc.flags << #{options[:cc][:flags].inspect}\n" if options[:cc][:flags]
      build += "  end\n\n"
    end

    if options[:linker]
      build += "  conf.linker do |linker|\n"
      build += "    linker.command = #{options[:linker][:command].inspect}\n" if options[:linker][:command]
      build += "    linker.flags << #{options[:linker][:flags].inspect}\n" if options[:linker][:flags]
      build += "  end\n\n"
    end

    build
  end
end

define_platform "host", HostPlatform
