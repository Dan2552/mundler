module Mundler
  def self.with_clean_env(&blk)
    if defined?(Bundler) && Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env(&blk)
    elsif defined?(Bundler)
      Bundler.with_clean_env(&blk)
    else
      blk.call
    end
  end
end
