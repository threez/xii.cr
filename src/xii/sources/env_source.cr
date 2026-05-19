# Use the low-level system env instead of `require "env"` to avoid pulling in
# the top-level ENV module, which can cause macro expansion failures in
# downstream projects where ENV is not yet defined at compile time.
require "crystal/system/env"

# Source that reads from process environment variables.
#
# Looks up the environment variable named by `option.env`.
#
# ```
# source = Xii::EnvSource.new
# source.get(option) # => ENV[option.env]? or nil
# ```
module Xii
  class EnvSource < Source
    def get(option : Option) : String?
      Crystal::System::Env.get(option.env)
    end
  end
end
