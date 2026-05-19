module Xii
  # Raised when a required configuration field has no environment variable set,
  # no YAML value, and no default.
  #
  # ```
  # begin
  #   config = MyApp::Config.load
  # rescue ex : Xii::MissingVariableError
  #   puts ex.variable # => "DATABASE_URL"
  #   puts ex.message  # => "Required environment variable 'DATABASE_URL' is not set and has no default value"
  # end
  # ```
  class MissingVariableError < Exception
    # The name of the missing environment variable (e.g. `"DATABASE_URL"`).
    getter variable : String

    # :nodoc:
    def initialize(@variable : String)
      super("Required environment variable '#{@variable}' is not set and has no default value")
    end
  end
end
