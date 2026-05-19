module Xii
  # Describes a single configuration field and its metadata.
  #
  # Returned by the generated `self.options` class method on any config class
  # that includes `Xii::Configurable`. Useful for introspection, generating
  # documentation, or building CLI help output.
  #
  # ```
  # MyApp::Config.options.each do |opt|
  #   puts "#{opt.env} (#{opt.type}) — #{opt.description}"
  # end
  # ```
  record Option,
    # Field name as declared in the config class (e.g. `"port"`).
    name : String,
    # Environment variable name (e.g. `"PORT"`).
    env : String,
    # Crystal type as a string (e.g. `"Int32"`, `"String?"`, `"Array(String)"`).
    type : String,
    # Default value as a string, or `nil` for required and nilable fields.
    default : String?,
    # `true` when the field has no default and is not nilable — loading raises
    # `Xii::MissingVariableError` if no source provides a value.
    required : Bool,
    # Human-readable description from the `@[Xii::Field(description: ...)]`
    # annotation, or an empty string when none was provided.
    description : String
end
