require "../src/xii"

# Basic ENV-only configuration — no config file needed.
# Fields are read from environment variables with type conversion and defaults.

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_HOST", description: "HTTP server host")]
  getter host : String = "localhost"

  @[Xii::Field(env: "APP_PORT", description: "HTTP server port")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "APP_DEBUG", description: "Enable debug logging")]
  getter debug : Bool = false

  @[Xii::Field(env: "APP_SECRET", description: "Optional signing secret")]
  getter secret : String?

  @[Xii::Field(env: "APP_TAGS", description: "Comma-separated tags")]
  getter tags : Array(String) = [] of String
end

puts "--- defaults (no ENV set) ---"
ENV.delete("APP_HOST")
ENV.delete("APP_PORT")
ENV.delete("APP_DEBUG")
ENV.delete("APP_SECRET")
ENV.delete("APP_TAGS")

config = AppConfig.load
puts "host:        #{config.host}"
puts "port:        #{config.port}"
puts "debug:       #{config.debug}"
puts "secret:      #{config.secret.inspect}"
puts "tags:        #{config.tags.inspect}"
puts "production?: #{config.production?}"
puts "development?:#{config.development?}"

puts
puts "--- with ENV overrides ---"
ENV["APP_HOST"] = "0.0.0.0"
ENV["APP_PORT"] = "3000"
ENV["APP_DEBUG"] = "true"
ENV["APP_SECRET"] = "s3cret"
ENV["APP_TAGS"] = "web, api, v2"
ENV["APP_ENV"] = "production"

config = AppConfig.load
puts "host:        #{config.host}"
puts "port:        #{config.port}"
puts "debug:       #{config.debug}"
puts "secret:      #{config.secret.inspect}"
puts "tags:        #{config.tags.inspect}"
puts "production?: #{config.production?}"
puts "development?:#{config.development?}"

puts
puts "--- help table ---"
AppConfig.help
