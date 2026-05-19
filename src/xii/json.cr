require "../xii"
require "./sources/json_source"

module Xii
  class Resolver
    # Build the standard source chain for a YAML or JSON config file.
    #
    # Handles `.json` files. If `require "xii/yaml"` is also loaded,
    # `.yml`/`.yaml` files are handled too (order of require does not matter).
    # The chain is: ENV > file source > defaults.
    def self.for_file(path : String, env : String) : self
      case File.extname(path)
      when ".json"
        sources = [EnvSource.new, JsonSource.new(path, env), DefaultSource.new] of Source
        new(sources)
      else
        previous_def
      end
    end
  end
end
