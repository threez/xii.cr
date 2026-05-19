require "../src/xii"

# Required and nilable fields.
# Required fields raise Xii::MissingVariableError when no value is found.
# Nilable fields return nil rather than raising.

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_API_KEY")]
  getter api_key : String # required — no default, not nilable

  @[Xii::Field(env: "APP_WEBHOOK_SECRET")]
  getter webhook_secret : String? # nilable — returns nil when unset

  @[Xii::Field(env: "APP_PORT")]
  getter port : Int32 = 8080 # optional — has a default
end

ENV.delete("APP_API_KEY")
ENV.delete("APP_WEBHOOK_SECRET")
ENV.delete("APP_PORT")
ENV.delete("APP_ENV")

puts "--- required field missing ---"
begin
  AppConfig.load
rescue ex : Xii::MissingVariableError
  puts "Caught MissingVariableError: #{ex.message}"
  puts "Missing variable name: #{ex.variable}"
end

puts
puts "--- nilable and optional fields ---"
ENV["APP_API_KEY"] = "key-abc123"
config = AppConfig.load
puts "api_key:         #{config.api_key}"
puts "webhook_secret:  #{config.webhook_secret.inspect}  (nil — not set)"
puts "port:            #{config.port}  (default)"

puts
puts "--- all fields set ---"
ENV["APP_WEBHOOK_SECRET"] = "whsec_xyz"
ENV["APP_PORT"] = "3000"
config = AppConfig.load
puts "api_key:         #{config.api_key}"
puts "webhook_secret:  #{config.webhook_secret.inspect}"
puts "port:            #{config.port}"
