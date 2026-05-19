require "../src/xii"

# Typed array fields — comma-separated (or custom separator) values parsed
# into typed arrays. Whitespace is stripped, empty entries are rejected.

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_TAGS")]
  getter tags : Array(String) = [] of String

  @[Xii::Field(env: "APP_ALLOWED_ORIGINS", separator: "|")]
  getter allowed_origins : Array(String) = [] of String

  @[Xii::Field(env: "APP_PORTS")]
  getter ports : Array(Int32) = [] of Int32

  @[Xii::Field(env: "APP_WEIGHTS")]
  getter weights : Array(Float64) = [] of Float64

  @[Xii::Field(env: "APP_SMALL_IDS")]
  getter small_ids : Array(Int16) = [] of Int16

  @[Xii::Field(env: "APP_RATIOS")]
  getter ratios : Array(Float32) = [] of Float32
end

ENV.delete("APP_TAGS")
ENV.delete("APP_ALLOWED_ORIGINS")
ENV.delete("APP_PORTS")
ENV.delete("APP_WEIGHTS")
ENV.delete("APP_SMALL_IDS")
ENV.delete("APP_RATIOS")
ENV.delete("APP_ENV")

puts "--- defaults (empty arrays) ---"
config = AppConfig.load
puts "tags:            #{config.tags.inspect}"
puts "allowed_origins: #{config.allowed_origins.inspect}"
puts "ports:           #{config.ports.inspect}"
puts "weights:         #{config.weights.inspect}"

puts
puts "--- parsed from ENV ---"
ENV["APP_TAGS"] = "web, api, backend"
ENV["APP_ALLOWED_ORIGINS"] = "https://a.example.com|https://b.example.com"
ENV["APP_PORTS"] = "80, 443, 8080"
ENV["APP_WEIGHTS"] = "1.5, 2.75, 0.5"
ENV["APP_SMALL_IDS"] = "1, 2, 3"
ENV["APP_RATIOS"] = "0.1, 0.25, 0.5"

config = AppConfig.load
puts "tags:            #{config.tags.inspect}"
puts "allowed_origins: #{config.allowed_origins.inspect}"
puts "ports:           #{config.ports.inspect}"
puts "weights:         #{config.weights.inspect}"
puts "small_ids:       #{config.small_ids.inspect}"
puts "ratios:          #{config.ratios.inspect}"

puts
puts "--- empty entries rejected ---"
ENV["APP_TAGS"] = "a,,b, ,c"
config = AppConfig.load
puts "tags:            #{config.tags.inspect}  (empty entries dropped)"
