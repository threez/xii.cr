require "../src/xii"

# Custom source — implement Xii::Source to read from any backend.
# Here we use a plain Hash to simulate a secrets manager or remote config store.

class HashSource < Xii::Source
  def initialize(@data : Hash(String, String))
  end

  def get(option : Xii::Option) : String?
    @data[option.name]?
  end
end

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "APP_SECRET")]
  getter secret : String = "default-secret"

  @[Xii::Field(env: "APP_NAME")]
  getter name : String = "myapp"
end

ENV.delete("APP_PORT")
ENV.delete("APP_SECRET")
ENV.delete("APP_NAME")
ENV.delete("APP_ENV")

store = HashSource.new({
  "port"   => "4000",
  "secret" => "from-secrets-manager",
  "name"   => "from-store",
})

puts "--- values from custom source ---"
config = AppConfig.load(source: store)
puts "port:   #{config.port}"
puts "secret: #{config.secret}"
puts "name:   #{config.name}"

puts
puts "--- ENV overrides custom source ---"
ENV["APP_PORT"] = "9000"
config = AppConfig.load(source: store)
puts "port:   #{config.port}  (from ENV)"
puts "secret: #{config.secret}  (from custom source)"
