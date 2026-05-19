require "../xii"
require "./sources/yaml_source"

module Xii
  class Resolver
    # Build the standard source chain for a YAML or JSON config file.
    #
    # Handles `.yml`/`.yaml` files. If `require "xii/json"` is also loaded,
    # `.json` files are handled too (order of require does not matter).
    # The chain is: ENV > file source > defaults.
    def self.for_file(path : String, env : String) : self
      case File.extname(path)
      when ".yml", ".yaml"
        sources = [EnvSource.new, YamlSource.new(path, env), DefaultSource.new] of Source
        new(sources)
      else
        previous_def
      end
    end
  end
end
