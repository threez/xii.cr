require "yaml"

# YAML configuration file source.
#
# Reads a YAML file structured with top-level keys for each environment
# (`development`, `production`, ...) and field names as nested keys.
#
# ```yaml
# development:
#   port: 3000
#   database_url: postgres://localhost/myapp_dev
#
# production:
#   port: 8080
#   database_url: postgres://db.internal/myapp
# ```
#
# ```
# source = Xii::YamlSource.new("config.yml", "development")
# source.get(option) # => "3000"
# ```
module Xii
  class YamlSource < Source
    @section : YAML::Any?

    # Parses *path* and selects the section for *env*.
    #
    # If the file does not exist or the section is absent, all `get` calls
    # return `nil` (the source is effectively inactive).
    def initialize(path : String, env : String)
      @section = if File.exists?(path)
                   YAML.parse(File.read(path))[env]?
                 end
    end

    # Returns the raw string value for *option* from the YAML section, or
    # `nil` if the key is absent.
    def get(option : Option) : String?
      if section = @section
        if val = section[option.name]?
          return val.as_s? || val.raw.to_s
        end
      end
      nil
    end
  end
end
