# Abstract base class for configuration sources.
#
# A source provides field lookups and returns raw string values.
# Sources are queried in priority order by the `Xii::Resolver` — the first
# source to return a non-nil value wins.
#
# ### Built-in sources
#
# - `Xii::EnvSource` — reads from process environment variables
# - `Xii::DefaultSource` — returns compile-time defaults
# - `Xii::YamlSource` — reads from a YAML config file
# - `Xii::JsonSource` — reads from a JSON config file
#
# ### Implementing a custom source
#
# ```
# class TomlSource < Xii::Source
#   def initialize(path : String, env : String)
#     # parse the file, select the env section
#   end
#
#   def get(option : Xii::Option) : String?
#     # look up the field, return raw string or nil
#   end
# end
# ```
module Xii
  abstract class Source
    # Look up a value for the given *option*.
    #
    # Returns the raw string value, or `nil` if this source has no value.
    abstract def get(option : Option) : String?
  end
end
