require "../src/xii"
require "../src/xii/json"

# JSON file fallback — same priority rules as YAML: ENV wins, then file, then defaults.

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "APP_DATABASE_URL")]
  getter database_url : String = "postgres://localhost/myapp"

  @[Xii::Field(env: "APP_RATE_LIMIT")]
  getter rate_limit : Int32 = 10
end

config_path = File.join(Dir.tempdir, "env_example_config.json")
File.write(config_path, %(
  {
    "development": {
      "port": 3000,
      "database_url": "postgres://localhost/myapp_dev",
      "rate_limit": 5
    },
    "production": {
      "port": 8080,
      "database_url": "postgres://db.internal/myapp",
      "rate_limit": 100
    }
  }
))

ENV.delete("APP_PORT")
ENV.delete("APP_DATABASE_URL")
ENV.delete("APP_RATE_LIMIT")

puts "--- development (from JSON file) ---"
ENV["APP_ENV"] = "development"
config = AppConfig.load(path: config_path)
puts "port:         #{config.port}"
puts "database_url: #{config.database_url}"
puts "rate_limit:   #{config.rate_limit}"

puts
puts "--- production (from JSON file) ---"
ENV["APP_ENV"] = "production"
config = AppConfig.load(path: config_path)
puts "port:         #{config.port}"
puts "database_url: #{config.database_url}"
puts "rate_limit:   #{config.rate_limit}"

puts
puts "--- ENV overrides JSON ---"
ENV["APP_PORT"] = "7777"
config = AppConfig.load(path: config_path)
puts "port:         #{config.port}  (from ENV)"
puts "database_url: #{config.database_url}  (from JSON)"

File.delete(config_path)
