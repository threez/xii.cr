module Xii
  # Annotation for declaring configuration fields loaded from environment
  # variables.
  #
  # Apply to instance variables (with `getter`) in a class that includes
  # `Xii::Configurable`.
  #
  # ### Parameters
  #
  # - **env** (`String`) — environment variable name (required)
  # - **separator** (`String`) — delimiter for `Array` fields (default `","`)
  # - **description** (`String`) — human-readable description; supports
  #   `${ENV}`, `${TYPE}`, and `${DEFAULT}` template variables
  #
  # ### Example
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
  #
  #   @[Xii::Field(env: "TAGS", separator: "|")]
  #   getter tags : Array(String) = [] of String
  # end
  # ```
  annotation Field
  end

  # DSL for declaring typed configuration loaded from environment variables.
  #
  # Include this module in a class and annotate `getter` declarations with
  # `@[Xii::Field]`. The module generates `self.load`, `self.options`, and
  # `self.help` at compile time by reading annotations from instance variables.
  #
  # The generated `initialize(*, __env_resolver:)` is internal and used only
  # by `self.load`. To construct instances directly (e.g. in tests), define
  # your own `def initialize` with the fields you need.
  #
  # ### Supported types
  #
  # `String`, `String?`, `Bool`, `Int8`..`Int64`, `UInt8`..`UInt64`,
  # `Float32`, `Float64`, `Array(String)`, `Array(Int32)`, etc.
  #
  # ### Example
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
  # config.port        # => 8080
  # config.production? # => false
  # ```
  module Configurable
    macro included
      # Internal constructor used by `self.load`. Resolves and converts every
      # `@[Xii::Field]` ivar from the given resolver.
      def initialize(*, __env_resolver _resolver : ::Xii::Resolver)
        {% verbatim do %}
          {% begin %}
            {% for ivar in @type.instance_vars %}
              {% if ann = ivar.annotation(::Xii::Field) %}
                {%
                  type_str = ivar.type.resolve.stringify
                  is_nilable = ivar.type.resolve.nilable?
                  has_default = ivar.has_default_value?
                  separator = ann[:separator] || ","
                %}

                {% if has_default && !type_str.starts_with?("Array(") %}
                  _opt_default_{{ivar.id}} = ({{ivar.default_value}}).to_s
                {% else %}
                  _opt_default_{{ivar.id}} = nil
                {% end %}

                _opt_{{ivar.id}} = ::Xii::Option.new(
                  name: {{ivar.id.stringify}},
                  env: {{ann[:env]}},
                  type: {{type_str}},
                  default: _opt_default_{{ivar.id}},
                  required: {{!has_default && !is_nilable}},
                  description: "",
                )
                _raw_{{ivar.id}} = _resolver.resolve!(_opt_{{ivar.id}})

                {% if type_str == "String" %}
                  @{{ivar.id}} = _raw_{{ivar.id}} || {{has_default ? ivar.default_value : ""}}

                {% elsif is_nilable && ivar.type.resolve.union_types.any? { |t| t == String } %}
                  @{{ivar.id}} = _raw_{{ivar.id}}

                {% elsif type_str == "Bool" %}
                  @{{ivar.id}} = if _s = _raw_{{ivar.id}}
                    ::Xii.parse_bool(_s)
                  else
                    {{has_default ? ivar.default_value : false}}
                  end

                {% elsif type_str.starts_with?("Array(") %}
                  {% array_inner = ivar.type.type_vars.first.resolve %}
                  @{{ivar.id}} = if _s = _raw_{{ivar.id}}
                    _parts = ::Xii.split_array(_s, {{separator}})
                    {% if array_inner != String %}
                      _parts.map { |_e| {{array_inner}}.new(_e) }
                    {% else %}
                      _parts
                    {% end %}
                  else
                    {{has_default ? ivar.default_value : "[] of #{ivar.type.type_vars.first}".id}}
                  end

                {% elsif is_nilable %}
                  {% inner = ivar.type.resolve.union_types.reject { |t| t == Nil }.first %}
                  @{{ivar.id}} = _raw_{{ivar.id}}.try { |_s| {{inner}}.new(_s) }

                {% else %}
                  @{{ivar.id}} = {{ivar.type.resolve}}.new(_raw_{{ivar.id}} || {{ivar.default_value.stringify}})
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end

      # Load configuration from the environment and an optional file or custom
      # source.
      #
      # - *env* — environment name (default: `APP_ENV` env var, or
      #   `"development"`). Selects the section in file-based sources.
      # - *path* — path to a config file. Requires `require "xii/yaml"` for
      #   `.yml`/`.yaml` or `require "xii/json"` for `.json`. `nil` (the
      #   default) means no file source — no filesystem access occurs.
      # - *source* — a custom `Xii::Source` instance inserted into the resolver
      #   chain between `EnvSource` and `DefaultSource`. Takes precedence over
      #   *path* when both are given.
      #
      # The resolution chain is always: ENV > file/custom source > defaults.
      #
      # ```
      # MyApp::Config.load
      # MyApp::Config.load(path: "config.yml")        # requires "xii/yaml"
      # MyApp::Config.load(path: "config.json")       # requires "xii/json"
      # MyApp::Config.load(env: "production", path: ENV["CONFIG_FILE"]?)
      # MyApp::Config.load(source: MyTomlSource.new("config.toml", "production"))
      # ```
      def self.load(env : String? = nil, path : String? = nil, source : ::Xii::Source? = nil) : self
        _env = env || ::ENV.fetch("APP_ENV", "development")
        _resolver = if source
                      ::Xii::Resolver.new([::Xii::EnvSource.new, source, ::Xii::DefaultSource.new] of ::Xii::Source)
                    elsif path
                      ::Xii::Resolver.for_file(path, _env)
                    else
                      ::Xii::Resolver.new([::Xii::EnvSource.new, ::Xii::DefaultSource.new] of ::Xii::Source)
                    end
        new(__env_resolver: _resolver)
      end

      # Returns `true` if the current environment is `"production"`.
      def production? : Bool
        ::ENV["APP_ENV"]? == "production"
      end

      # Returns `true` if the current environment is `"development"` or unset.
      def development? : Bool
        _env_val = ::ENV["APP_ENV"]?
        _env_val.nil? || _env_val == "development"
      end

      # Returns metadata for all declared `@[Xii::Field]` entries.
      def self.options : Array(::Xii::Option)
        _opts = [] of ::Xii::Option
        {% verbatim do %}
          {% begin %}
            {% for ivar in @type.instance_vars %}
              {% if ann = ivar.annotation(::Xii::Field) %}
                {%
                  is_nilable = ivar.type.resolve.nilable?
                  if is_nilable
                    non_nil = ivar.type.resolve.union_types.reject { |t| t == Nil }
                    type_name = non_nil.first.stringify + "?"
                  else
                    type_name = ivar.type.resolve.stringify
                  end
                  has_default = ivar.has_default_value?
                  is_required = !has_default && !is_nilable
                  description = ann[:description] || ""
                %}

                {% if has_default && !type_name.starts_with?("Array(") %}
                  _default = ({{ivar.default_value}}).to_s
                {% else %}
                  _default = nil
                {% end %}

                _default_display = _default || {{is_nilable ? "(nil)" : "(required)"}}

                {% if description != "" %}
                  _desc = {{description}}
                    .gsub("${ENV}", {{ann[:env]}})
                    .gsub("${TYPE}", {{type_name}})
                    .gsub("${DEFAULT}", _default_display)
                {% else %}
                  _desc = ""
                {% end %}

                _opts << ::Xii::Option.new(
                  name: {{ivar.id.stringify}},
                  env: {{ann[:env]}},
                  type: {{type_name}},
                  default: _default,
                  required: {{is_required}},
                  description: _desc,
                )
              {% end %}
            {% end %}
          {% end %}
        {% end %}
        _opts
      end

      # Prints a CLI-friendly table of all environment variables.
      def self.help(io : IO = STDOUT) : Nil
        ::Xii.help(self.options, io: io)
      end
    end
  end
end
