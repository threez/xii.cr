# Source that returns the default value declared on a field.
#
# Returns `option.default` — the stringified default from the field
# declaration (e.g. `= 8080` becomes `"8080"`). Returns `nil` for required
# fields and nilable fields that have no default.
#
# ```
# source = Xii::DefaultSource.new
# source.get(option) # => option.default
# ```
module Xii
  class DefaultSource < Source
    def get(option : Option) : String?
      option.default
    end
  end
end
