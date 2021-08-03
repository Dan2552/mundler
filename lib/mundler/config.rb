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
      @env = {}
    end

    attr_reader :mruby
    attr_reader :platform_types
    attr_reader :env

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
        #{hashable_string_for_hash(env)}
        #{gemboxes.inspect}
        #{gems.inspect}
      HASHABLE
    end

    private

    def hashable_string_for_hash(hash)
      str = "{"
      sorted_keys = hash.keys.sort

      sorted_keys.each do |key|
        str = str + "#{key}=>#{hash[key]}"
      end

      str + "}"
    end
  end
end
