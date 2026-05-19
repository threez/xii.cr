require "./xii/version"
require "./xii/error"
require "./xii/option"
require "./xii/source"
require "./xii/sources/env_source"
require "./xii/sources/default_source"
require "./xii/resolver"
require "./xii/configurable"

# Declarative, type-safe configuration from environment variables.
#
# Include `Xii::Configurable` in a class and annotate `getter` declarations
# with `@[Xii::Field]` to declare typed configuration fields that load from
# ENV (with optional file fallback from YAML, JSON, or a custom `Xii::Source`).
#
# The resolver queries a chain of sources in priority order. The default
# chain is: `EnvSource` > file source > `DefaultSource`.
#
# ```
# class MyApp::Config
#   include Xii::Configurable
#
#   @[Xii::Field(env: "PORT")]
#   getter port : Int32 = 8080
#
#   @[Xii::Field(env: "DATABASE_URL")]
#   getter database_url : String
#
#   @[Xii::Field(env: "DEBUG")]
#   getter debug : Bool = false
#
#   @[Xii::Field(env: "SECRET")]
#   getter secret : String?
# end
#
# config = MyApp::Config.load
# config.port # => 8080
# ```
module Xii
end
