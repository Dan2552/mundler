module Mundler
  class Config
    def initialize
      @mruby = {
        url: "https://github.com/mruby/mruby",
        branch: "stable"
      }

      @platforms = []
      @gemboxes = []
      @gems = []
      @platform_types = {}
    end

    attr_reader :mruby
    attr_reader :platform_types

    def hex
      Digest::MD5.hexdigest(to_s)
    end

    def gemboxes
      @gemboxes.sort!
    end

    def gems
      @gems.sort_by! { |platform| platform[:name] }
    end

    def platforms
      @platforms.sort_by! { |platform| platform[:name] }
    end

    def to_s
      <<~HASHABLE
        #{mruby.inspect}
        #{platforms.inspect}
        #{platform_types.keys.sort.inspect}
        #{gemboxes.inspect}
        #{gems.inspect}
      HASHABLE
    end
  end
end
