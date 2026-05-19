require "../src/xii"

# Introspection — self.options returns structured metadata for every field.
# self.help prints a formatted table. Descriptions support template variables.

class AppConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_PORT", description: "HTTP listen port (default: ${DEFAULT})")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "DATABASE_URL", description: "Database connection string (${TYPE})")]
  getter database_url : String

  @[Xii::Field(env: "APP_DEBUG", description: "Enable debug mode (${TYPE}, default: ${DEFAULT})")]
  getter debug : Bool = false

  @[Xii::Field(env: "APP_SECRET", description: "Optional secret for ${ENV}")]
  getter secret : String?

  @[Xii::Field(env: "APP_WORKERS", description: "Worker thread count")]
  getter workers : Int32 = 4
end

puts "--- self.options ---"
AppConfig.options.each do |opt|
  required = opt.required ? "required" : (opt.default || "nil")
  puts "#{opt.env.ljust(16)} #{opt.type.ljust(10)} #{required.ljust(12)} #{opt.description}"
end

puts
puts "--- self.help ---"
AppConfig.help

puts
puts "--- self.help to STDERR ---"
AppConfig.help(STDERR)
