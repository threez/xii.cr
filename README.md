# XII (Roman numeral for 12)

Declarative, type-safe configuration from environment variables for Crystal,
inspired by the [twelve-factor app](https://12factor.net/config) methodology.

Annotate `getter` fields with `@[Xii::Field]`, and `xii` generates a typed
loader that reads from ENV, converts values, validates required fields, and
exposes immutable getters.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     xii:
       github: threez/xii.cr
   ```

2. Run `shards install`

## Usage

The library supports two modes of operation: **ENV-only** for pure
twelve-factor-style configuration, and **ENV + file** for projects that
keep a local config file with per-environment defaults.

### ENV-only

The simplest mode. Annotate each `getter` with `@[Xii::Field(env: "VAR_NAME")]`
and set a Crystal default value for optional fields:

```crystal
require "xii"

class MyApp::Config
  include Xii::Configurable

  @[Xii::Field(env: "PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "DATABASE_URL")]
  getter database_url : String

  @[Xii::Field(env: "DEBUG")]
  getter debug : Bool = false

  @[Xii::Field(env: "SECRET")]
  getter secret : String?

  @[Xii::Field(env: "ALLOWED_ORIGINS")]
  getter allowed_origins : Array(String) = [] of String
end

config = MyApp::Config.load
config.port        # => 8080
config.debug       # => false
config.secret      # => nil (not set)
config.production? # => false
```

This is the right choice when all configuration comes from the process
environment (containers, systemd units, PaaS platforms, CI, etc.).

### ENV + config file (YAML or JSON)

File format support is opt-in. Add the appropriate require before using
`path:` with `load`:

```crystal
require "xii/yaml"   # enables .yml / .yaml
require "xii/json"   # enables .json
```

Pass a `path:` to `load` to enable a file-based fallback. Files are structured
with top-level keys for each environment (`development`, `production`, ...) and
field names as nested keys:

```crystal
require "xii"
require "xii/yaml"

class MyApp::Config
  include Xii::Configurable

  @[Xii::Field(env: "PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "DATABASE_URL")]
  getter database_url : String = "postgres://localhost/myapp"

  @[Xii::Field(env: "KMS_URL")]
  getter kms_url : String = "http://localhost:3000"

  @[Xii::Field(env: "JWT_SECRET")]
  getter jwt_secret : String?

  @[Xii::Field(env: "RATE_LIMIT")]
  getter rate_limit : Int32 = 30
end

config = MyApp::Config.load(path: "data/config.yml")
```

```yaml
# data/config.yml
development:
  database_url: postgres://localhost/myapp_dev
  kms_url: http://localhost:3000

production:
  database_url: postgres://db.internal/myapp
  kms_url: https://kms.internal
  rate_limit: 100
```

Or with JSON:

```crystal
require "xii"
require "xii/json"

config = MyApp::Config.load(path: "data/config.json")
```

```json
{
  "development": {
    "database_url": "postgres://localhost/myapp_dev",
    "kms_url": "http://localhost:3000"
  },
  "production": {
    "database_url": "postgres://db.internal/myapp",
    "kms_url": "https://kms.internal",
    "rate_limit": 100
  }
}
```

The environment section is selected by the `APP_ENV` environment variable
(defaulting to `"development"`). Pass `env:` to override:

```crystal
config = MyApp::Config.load(path: "config.yml", env: "production")
```

The config file path is fully runtime-configurable — read it from an
environment variable, a CLI flag, or any other source:

```crystal
config = MyApp::Config.load(path: ENV.fetch("CONFIG_FILE", "config.yml"))
```

Pass `nil` (or omit `path:`) to disable file loading and use only ENV and
field defaults:

```crystal
config = MyApp::Config.load         # ENV + defaults only
config = MyApp::Config.load(path: nil)  # same
```

### Custom sources

For formats beyond YAML and JSON, subclass `Xii::Source` and pass an instance
to `load` via `source:`:

```crystal
class TomlSource < Xii::Source
  def initialize(path : String, env : String)
    # parse file, select the env section
  end

  def get(option : Xii::Option) : String?
    # look up field by option.name, return raw string or nil
  end
end

config = MyApp::Config.load(source: TomlSource.new("config.toml", "production"))
```

When `source:` is given it takes precedence over `path:`. The resolution chain
is always: ENV > custom source > defaults.

### Source chain and loading priority

Configuration is resolved by querying a chain of `Xii::Source` instances in
order. The first source to return a non-nil value wins.

The chain is:

1. **`Xii::EnvSource`** — reads process environment variables
2. **File or custom source** — `Xii::YamlSource` (opt-in via `require "xii/yaml"`),
   `Xii::JsonSource` (opt-in via `require "xii/json"`), or a custom `Xii::Source`
   (when `path:` or `source:` is passed to `load`)
3. **`Xii::DefaultSource`** — returns the field declaration default value

If no source provides a value: nilable types get `nil`, required fields
raise `Xii::MissingVariableError`.

### Field annotation options

| Option        | Description                                        | Required |
|---------------|----------------------------------------------------|----------|
| `env`         | Environment variable name to read                  | yes      |
| `separator`   | Delimiter for `Array` fields (default `","`)       | no       |
| `description` | Human-readable description (supports `${ENV}`, `${TYPE}`, `${DEFAULT}`) | no |

The default value is declared directly on the `getter` using Crystal's standard
ivar default syntax (`= value`).

### Supported types

| Type                  | ENV conversion                                          |
|-----------------------|---------------------------------------------------------|
| `String`              | Used as-is                                              |
| `String?`             | `nil` when not set                                      |
| `Bool`                | `"true"`, `"1"`, `"yes"` (case-insensitive) are `true` |
| `Int8` .. `Int64`     | Parsed with `.to_i8` .. `.to_i64`                       |
| `UInt8` .. `UInt64`   | Parsed with `.to_u8` .. `.to_u64`                       |
| `Float32`, `Float64`  | Parsed with `.to_f32`, `.to_f64`                        |
| `Array(String)`       | Split by separator, stripped, empty entries rejected    |
| `Array(Int32)`, etc.  | Split then parsed per element type                      |
| `Array(Float64)`, etc.| Split then parsed per element type                      |

### Required vs optional fields

A field's behavior when no value is found depends on its type and whether
an ivar default is declared:

```crystal
# Required — raises Xii::MissingVariableError if not set anywhere
@[Xii::Field(env: "API_KEY")]
getter api_key : String

# Optional with default — uses the default when not set
@[Xii::Field(env: "PORT")]
getter port : Int32 = 3000

# Nilable — returns nil when not set
@[Xii::Field(env: "SECRET")]
getter secret : String?
```

### Array fields

Array fields split the raw string by separator (default `","`), strip
whitespace from each entry, and reject empty entries. The element type
determines how each entry is parsed:

```crystal
# String arrays
@[Xii::Field(env: "TAGS")]
getter tags : Array(String) = [] of String

@[Xii::Field(env: "ORIGINS", separator: "|")]
getter origins : Array(String) = [] of String

# Integer arrays
@[Xii::Field(env: "PORTS")]
getter ports : Array(Int32) = [] of Int32

# Float arrays
@[Xii::Field(env: "WEIGHTS")]
getter weights : Array(Float64) = [] of Float64
```

```sh
export TAGS="web, api, backend"            # => ["web", "api", "backend"]
export ORIGINS="http://a.com|http://b.com" # => ["http://a.com", "http://b.com"]
export PORTS="80, 443, 8080"               # => [80, 443, 8080]
export WEIGHTS="1.5, 2.75, 0.5"            # => [1.5, 2.75, 0.5]
```

Supported element types: `String`, `Int8`..`Int64`, `UInt8`..`UInt64`,
`Float32`, `Float64`.

### Introspection and CLI help

Fields can include a `description` in the annotation for documentation and
CLI help output. Descriptions support `${ENV}`, `${TYPE}`, and `${DEFAULT}`
template variables that are substituted automatically:

```crystal
class MyApp::Config
  include Xii::Configurable

  @[Xii::Field(env: "PORT", description: "Listen port for the HTTP server")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "DATABASE_URL", description: "Database connection URL (${TYPE})")]
  getter database_url : String

  @[Xii::Field(env: "DEBUG", description: "Enable debug mode (default: ${DEFAULT})")]
  getter debug : Bool = false

  @[Xii::Field(env: "SECRET", description: "Optional secret for ${ENV}")]
  getter secret : String?
end
```

**`self.options`** returns an `Array(Xii::Option)` with structured metadata
for each field (name, env var, type, default, required flag, description):

```crystal
MyApp::Config.options.each do |opt|
  puts "#{opt.env} (#{opt.type}) — #{opt.description}"
end
```

**`self.help`** prints a formatted table to any IO (default `STDOUT`):

```crystal
MyApp::Config.help
```

```
Environment variables:

  PORT          Int32    8080        Listen port for the HTTP server
  DATABASE_URL  String   (required)  Database connection URL (String)
  DEBUG         Bool     false       Enable debug mode (default: false)
  SECRET        String?  (nil)       Optional secret for SECRET
```

You can also call `Xii.help(options, io:)` directly with any options array.

### Environment helpers

Every config class gets `production?` and `development?` instance methods that
check `APP_ENV`:

```crystal
config = MyApp::Config.load
config.production?   # => true when APP_ENV == "production"
config.development?  # => true when APP_ENV is "development" or not set
```

### Testing

In tests, set the relevant ENV vars and call `load` normally:

```crystal
with_env({"DATABASE_URL" => "postgres://localhost/test"}) do
  config = MyApp::Config.load
  config.database_url # => "postgres://localhost/test"
  config.port         # => 8080 (uses declared default)
end
```

## Development

```sh
make          # run fmt, lint, docs, and spec
make fmt      # format code
make lint     # run ameba linter
make spec     # run tests
make docs     # generate API docs
```

## Contributing

1. Fork it (<https://github.com/threez/env.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Vincent Landgraf](https://github.com/threez) - creator and maintainer
