require "../spec_helper"

class BasicConfig
  include Xii::Configurable

  @[Xii::Field(env: "TEST_PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "TEST_NAME")]
  getter name : String = "myapp"

  @[Xii::Field(env: "TEST_DEBUG")]
  getter debug : Bool = false

  @[Xii::Field(env: "TEST_TAGS")]
  getter tags : Array(String) = [] of String

  @[Xii::Field(env: "TEST_SECRET")]
  getter secret : String?

  @[Xii::Field(env: "TEST_RATIO")]
  getter ratio : Float64 = 1.5

  @[Xii::Field(env: "TEST_SMALL_PORT")]
  getter small_port : Int16 = 3000_i16
end

class RequiredConfig
  include Xii::Configurable

  @[Xii::Field(env: "TEST_REQUIRED_KEY")]
  getter api_key : String
end

class CustomSeparatorConfig
  include Xii::Configurable

  @[Xii::Field(env: "TEST_ORIGINS", separator: "|")]
  getter origins : Array(String) = [] of String
end

class TypedArrayConfig
  include Xii::Configurable

  @[Xii::Field(env: "TEST_PORTS")]
  getter ports : Array(Int32) = [] of Int32

  @[Xii::Field(env: "TEST_WEIGHTS")]
  getter weights : Array(Float64) = [] of Float64

  @[Xii::Field(env: "TEST_SMALL_IDS")]
  getter small_ids : Array(Int16) = [] of Int16

  @[Xii::Field(env: "TEST_RATIOS")]
  getter ratios : Array(Float32) = [] of Float32
end

class DocumentedConfig
  include Xii::Configurable

  @[Xii::Field(env: "APP_PORT", description: "Listen port for the HTTP server")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "DATABASE_URL", description: "Database connection URL")]
  getter database_url : String

  @[Xii::Field(env: "APP_DEBUG", description: "Enable debug mode (${TYPE}, default: ${DEFAULT})")]
  getter debug : Bool = false

  @[Xii::Field(env: "APP_SECRET", description: "Optional secret key for ${ENV}")]
  getter secret : String?

  @[Xii::Field(env: "WORKERS", description: "Number of worker threads")]
  getter workers : Int32 = 4
end

YAML_CONFIG_PATH = File.join(Dir.tempdir, "env_test_config.yml")
JSON_CONFIG_PATH = File.join(Dir.tempdir, "env_test_config.json")

class YamlConfig
  include Xii::Configurable

  @[Xii::Field(env: "YAML_TEST_PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "YAML_TEST_NAME")]
  getter name : String = "default"
end

class JsonConfig
  include Xii::Configurable

  @[Xii::Field(env: "JSON_TEST_PORT")]
  getter port : Int32 = 8080

  @[Xii::Field(env: "JSON_TEST_NAME")]
  getter name : String = "default"
end

private def with_env(vars : Hash(String, String), &)
  vars.each { |k, v| ENV[k] = v }
  yield
ensure
  vars.each_key { |k| ENV.delete(k) }
end

private def clear_env(*keys, &)
  keys.each { |k| ENV.delete(k) }
  yield
end

describe Xii::Configurable do
  describe "default values" do
    it "uses defaults when ENV vars are not set" do
      clear_env("TEST_PORT", "TEST_NAME", "TEST_DEBUG", "TEST_TAGS", "TEST_SECRET", "TEST_RATIO", "TEST_SMALL_PORT") do
        config = BasicConfig.load
        config.port.should eq(8080)
        config.name.should eq("myapp")
        config.debug.should eq(false)
        config.tags.should eq([] of String)
        config.secret.should be_nil
        config.ratio.should eq(1.5)
        config.small_port.should eq(3000_i16)
      end
    end
  end

  describe "ENV overrides" do
    it "reads values from ENV vars" do
      with_env({
        "TEST_PORT"       => "9090",
        "TEST_NAME"       => "prod-app",
        "TEST_DEBUG"      => "true",
        "TEST_TAGS"       => "web, api, backend",
        "TEST_SECRET"     => "s3cret",
        "TEST_RATIO"      => "2.75",
        "TEST_SMALL_PORT" => "443",
      }) do
        config = BasicConfig.load
        config.port.should eq(9090)
        config.name.should eq("prod-app")
        config.debug.should eq(true)
        config.tags.should eq(["web", "api", "backend"])
        config.secret.should eq("s3cret")
        config.ratio.should eq(2.75)
        config.small_port.should eq(443_i16)
      end
    end
  end

  describe "Bool parsing" do
    {% for truthy in ["true", "1", "yes", "TRUE", "Yes"] %}
      it "parses #{{{truthy}}} as true" do
        with_env({"TEST_DEBUG" => {{truthy}}}) do
          config = BasicConfig.load
          config.debug.should eq(true)
        end
      end
    {% end %}

    {% for falsy in ["false", "0", "no", "FALSE", "No", "anything"] %}
      it "parses #{{{falsy}}} as false" do
        with_env({"TEST_DEBUG" => {{falsy}}}) do
          config = BasicConfig.load
          config.debug.should eq(false)
        end
      end
    {% end %}
  end

  describe "Array(String)" do
    it "splits by comma and strips whitespace" do
      with_env({"TEST_TAGS" => " a , b , c "}) do
        config = BasicConfig.load
        config.tags.should eq(["a", "b", "c"])
      end
    end

    it "rejects empty entries" do
      with_env({"TEST_TAGS" => "a,,b,"}) do
        config = BasicConfig.load
        config.tags.should eq(["a", "b"])
      end
    end

    it "supports custom separator" do
      with_env({"TEST_ORIGINS" => "http://a.com|http://b.com"}) do
        config = CustomSeparatorConfig.load
        config.origins.should eq(["http://a.com", "http://b.com"])
      end
    end
  end

  describe "Array(Int32)" do
    it "parses comma-separated integers" do
      with_env({"TEST_PORTS" => "80, 443, 8080"}) do
        config = TypedArrayConfig.load
        config.ports.should eq([80, 443, 8080])
      end
    end

    it "returns empty array for empty default" do
      clear_env("TEST_PORTS", "TEST_WEIGHTS", "TEST_SMALL_IDS", "TEST_RATIOS") do
        config = TypedArrayConfig.load
        config.ports.should eq([] of Int32)
      end
    end
  end

  describe "Array(Float64)" do
    it "parses comma-separated floats" do
      with_env({"TEST_WEIGHTS" => "1.5, 2.75, 0.5"}) do
        config = TypedArrayConfig.load
        config.weights.should eq([1.5, 2.75, 0.5])
      end
    end
  end

  describe "Array(Int16)" do
    it "parses comma-separated int16 values" do
      with_env({"TEST_SMALL_IDS" => "1, 2, 3"}) do
        config = TypedArrayConfig.load
        config.small_ids.should eq([1_i16, 2_i16, 3_i16])
      end
    end
  end

  describe "Array(Float32)" do
    it "parses comma-separated float32 values" do
      with_env({"TEST_RATIOS" => "0.1, 0.2"}) do
        config = TypedArrayConfig.load
        config.ratios.should eq([0.1_f32, 0.2_f32])
      end
    end
  end

  describe "required fields" do
    it "raises MissingVariableError when a required field is not set" do
      clear_env("TEST_REQUIRED_KEY") do
        ex = expect_raises(Xii::MissingVariableError) do
          RequiredConfig.load
        end
        ex.variable.should eq("TEST_REQUIRED_KEY")
        ex.message.not_nil!.should contain("TEST_REQUIRED_KEY")
      end
    end

    it "loads when the required field is set" do
      with_env({"TEST_REQUIRED_KEY" => "abc123"}) do
        config = RequiredConfig.load
        config.api_key.should eq("abc123")
      end
    end
  end

  describe "nilable fields" do
    it "returns nil when not set" do
      clear_env("TEST_SECRET") do
        config = BasicConfig.load
        config.secret.should be_nil
      end
    end

    it "returns the value when set" do
      with_env({"TEST_SECRET" => "hello"}) do
        config = BasicConfig.load
        config.secret.should eq("hello")
      end
    end
  end

  describe "direct construction via load with ENV" do
    it "allows constructing config for testing by setting ENV vars" do
      with_env({
        "TEST_PORT"       => "3000",
        "TEST_NAME"       => "test",
        "TEST_DEBUG"      => "true",
        "TEST_TAGS"       => "a",
        "TEST_SECRET"     => "x",
        "TEST_RATIO"      => "0.5",
        "TEST_SMALL_PORT" => "80",
      }) do
        config = BasicConfig.load
        config.port.should eq(3000)
        config.name.should eq("test")
        config.debug.should eq(true)
        config.tags.should eq(["a"])
        config.secret.should eq("x")
      end
    end
  end

  describe "YAML fallback" do
    after_each { File.delete(YAML_CONFIG_PATH) if File.exists?(YAML_CONFIG_PATH) }

    it "reads values from YAML when ENV is not set" do
      File.write(YAML_CONFIG_PATH, <<-YAML
        development:
          port: 3000
          name: from-yaml
        YAML
      )
      clear_env("YAML_TEST_PORT", "YAML_TEST_NAME") do
        config = YamlConfig.load(path: YAML_CONFIG_PATH)
        config.port.should eq(3000)
        config.name.should eq("from-yaml")
      end
    end

    it "ENV overrides YAML" do
      File.write(YAML_CONFIG_PATH, <<-YAML
        development:
          port: 3000
          name: from-yaml
        YAML
      )
      with_env({"YAML_TEST_PORT" => "9999"}) do
        clear_env("YAML_TEST_NAME") do
          config = YamlConfig.load(path: YAML_CONFIG_PATH)
          config.port.should eq(9999)
          config.name.should eq("from-yaml")
        end
      end
    end

    it "falls back to default when neither ENV nor YAML is set" do
      clear_env("YAML_TEST_PORT", "YAML_TEST_NAME") do
        config = YamlConfig.load
        config.port.should eq(8080)
        config.name.should eq("default")
      end
    end

    it "reads the correct env section" do
      File.write(YAML_CONFIG_PATH, <<-YAML
        development:
          name: dev-app
        production:
          name: prod-app
        YAML
      )
      clear_env("YAML_TEST_PORT", "YAML_TEST_NAME") do
        with_env({"APP_ENV" => "production"}) do
          config = YamlConfig.load(path: YAML_CONFIG_PATH, env: "production")
          config.name.should eq("prod-app")
        end
      end
    end
  end

  describe "JSON fallback" do
    after_each { File.delete(JSON_CONFIG_PATH) if File.exists?(JSON_CONFIG_PATH) }

    it "reads values from JSON when ENV is not set" do
      File.write(JSON_CONFIG_PATH, %({"development": {"port": 3000, "name": "from-json"}}))
      clear_env("JSON_TEST_PORT", "JSON_TEST_NAME") do
        config = JsonConfig.load(path: JSON_CONFIG_PATH)
        config.port.should eq(3000)
        config.name.should eq("from-json")
      end
    end

    it "ENV overrides JSON" do
      File.write(JSON_CONFIG_PATH, %({"development": {"port": 3000, "name": "from-json"}}))
      with_env({"JSON_TEST_PORT" => "9999"}) do
        clear_env("JSON_TEST_NAME") do
          config = JsonConfig.load(path: JSON_CONFIG_PATH)
          config.port.should eq(9999)
          config.name.should eq("from-json")
        end
      end
    end

    it "falls back to default when neither ENV nor JSON is set" do
      clear_env("JSON_TEST_PORT", "JSON_TEST_NAME") do
        config = JsonConfig.load
        config.port.should eq(8080)
        config.name.should eq("default")
      end
    end

    it "reads the correct env section" do
      File.write(JSON_CONFIG_PATH, %({"development": {"name": "dev-app"}, "production": {"name": "prod-app"}}))
      clear_env("JSON_TEST_PORT", "JSON_TEST_NAME") do
        config = JsonConfig.load(path: JSON_CONFIG_PATH, env: "production")
        config.name.should eq("prod-app")
      end
    end
  end

  describe "custom source" do
    it "uses a custom source in the chain" do
      File.write(YAML_CONFIG_PATH, <<-YAML
        development:
          port: 4000
          name: from-source
        YAML
      )
      source = Xii::YamlSource.new(YAML_CONFIG_PATH, "development")
      clear_env("YAML_TEST_PORT", "YAML_TEST_NAME") do
        config = YamlConfig.load(source: source)
        config.port.should eq(4000)
        config.name.should eq("from-source")
      end
      File.delete(YAML_CONFIG_PATH)
    end

    it "ENV still overrides custom source" do
      File.write(YAML_CONFIG_PATH, <<-YAML
        development:
          port: 4000
          name: from-source
        YAML
      )
      source = Xii::YamlSource.new(YAML_CONFIG_PATH, "development")
      with_env({"YAML_TEST_PORT" => "9999"}) do
        clear_env("YAML_TEST_NAME") do
          config = YamlConfig.load(source: source)
          config.port.should eq(9999)
          config.name.should eq("from-source")
        end
      end
      File.delete(YAML_CONFIG_PATH)
    end
  end

  describe "self.options" do
    it "returns all field metadata" do
      opts = DocumentedConfig.options
      opts.size.should eq(5)
    end

    it "populates option fields correctly for a field with default" do
      opt = DocumentedConfig.options[0]
      opt.name.should eq("port")
      opt.env.should eq("APP_PORT")
      opt.type.should eq("Int32")
      opt.default.should eq("8080")
      opt.required.should eq(false)
      opt.description.should eq("Listen port for the HTTP server")
    end

    it "marks required fields correctly" do
      opt = DocumentedConfig.options[1]
      opt.name.should eq("database_url")
      opt.env.should eq("DATABASE_URL")
      opt.type.should eq("String")
      opt.default.should be_nil
      opt.required.should eq(true)
      opt.description.should eq("Database connection URL")
    end

    it "marks nilable fields as not required with nil default" do
      opt = DocumentedConfig.options[3]
      opt.name.should eq("secret")
      opt.type.should eq("String?")
      opt.default.should be_nil
      opt.required.should eq(false)
    end

    it "substitutes ${TYPE} and ${DEFAULT} template variables" do
      opt = DocumentedConfig.options[2]
      opt.description.should eq("Enable debug mode (Bool, default: false)")
    end

    it "substitutes ${ENV} template variable" do
      opt = DocumentedConfig.options[3]
      opt.description.should eq("Optional secret key for APP_SECRET")
    end

    it "returns empty description when none is provided" do
      opts = BasicConfig.options
      opts.each do |opt|
        opt.description.should eq("")
      end
    end
  end

  describe "self.help" do
    it "writes formatted output to IO" do
      io = IO::Memory.new
      DocumentedConfig.help(io)
      output = io.to_s

      output.should contain("Environment variables:")
      output.should contain("APP_PORT")
      output.should contain("DATABASE_URL")
      output.should contain("(required)")
      output.should contain("Listen port for the HTTP server")
      output.should contain("Enable debug mode (Bool, default: false)")
    end

    it "aligns columns" do
      io = IO::Memory.new
      DocumentedConfig.help(io)
      lines = io.to_s.lines.reject(&.empty?)

      # All data lines (skip header) should start with 2-space indent
      data_lines = lines[1..]
      data_lines.each do |line|
        line.should start_with("  ")
      end
    end
  end

  describe "environment helpers" do
    it "production? returns true when APP_ENV is production" do
      with_env({"APP_ENV" => "production"}) do
        BasicConfig.load.production?.should eq(true)
        BasicConfig.load.development?.should eq(false)
      end
    end

    it "development? returns true when APP_ENV is development" do
      with_env({"APP_ENV" => "development"}) do
        BasicConfig.load.production?.should eq(false)
        BasicConfig.load.development?.should eq(true)
      end
    end

    it "development? returns true when APP_ENV is not set" do
      clear_env("APP_ENV") do
        BasicConfig.load.development?.should eq(true)
      end
    end
  end
end
