module Xii
  # Resolves raw string values by querying a chain of sources in priority order.
  #
  # The first source to return a non-nil value wins. The standard priority is:
  # ENV > file source > default. File-format support is opt-in — see
  # `require "xii/yaml"` and `require "xii/json"`.
  class Resolver
    # The ordered list of sources queried during resolution.
    getter sources : Array(Source)

    # Creates a resolver that queries *sources* in order.
    def initialize(@sources : Array(Source))
    end

    # :nodoc:
    # Base implementation — always raises. Overridden by `require "xii/yaml"`
    # and `require "xii/json"` to handle their respective file formats.
    def self.for_file(path : String, env : String) : self
      raise ArgumentError.new(
        "No config file format handler loaded for #{path}. " \
        "Add `require \"env/yaml\"` for .yml/.yaml or `require \"env/json\"` for .json."
      )
    end

    # Resolve a raw string value for the given option.
    #
    # Queries each source in order, returning the first non-nil value.
    # Returns `nil` when no source provides a value.
    def resolve(option : Option) : String?
      @sources.each do |source|
        if value = source.get(option)
          return value
        end
      end
      nil
    end

    # Resolve a raw string value for the given option, raising if it is required
    # and no source provides a value.
    #
    # Returns `nil` for nilable fields with no value — the caller is responsible
    # for treating `nil` as the appropriate zero value for the field type.
    # Raises `Xii::MissingVariableError` when `option.required` is `true` and
    # all sources return `nil`.
    def resolve!(option : Option) : String?
      value = resolve(option)
      if value.nil? && option.required
        raise MissingVariableError.new(option.env)
      end
      value
    end
  end

  # :nodoc:
  # Parse a boolean from a string value.
  #
  # Accepts `"true"`, `"1"`, `"yes"` (case-insensitive) as `true`.
  # Everything else is `false`.
  def self.parse_bool(value : String) : Bool
    {"true", "1", "yes"}.includes?(value.downcase)
  end

  # :nodoc:
  # Split a string into an array by separator, stripping whitespace and
  # rejecting empty entries.
  def self.split_array(value : String, separator : String = ",") : Array(String)
    value.split(separator).map(&.strip).reject(&.empty?)
  end

  # Print a CLI-friendly table of options to *io*.
  #
  # ```
  # Xii.help(MyApp::Config.options)
  # Xii.help(MyApp::Config.options, io: STDERR)
  # ```
  def self.help(options : Array(Option), io : IO = STDOUT) : Nil
    return if options.empty?

    max_env = options.max_of(&.env.size)
    max_type = options.max_of(&.type.size)
    max_default = options.max_of { |opt| (opt.default || (opt.required ? "(required)" : "(nil)")).size }

    io.puts "Environment variables:"
    io.puts
    options.each do |opt|
      def_str = opt.default || (opt.required ? "(required)" : "(nil)")
      io.print "  "
      io.print opt.env.ljust(max_env + 2)
      io.print opt.type.ljust(max_type + 2)
      io.print def_str.ljust(max_default + 2)
      io.puts opt.description
    end
  end
end
