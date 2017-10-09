require "guard"
require "guard/deprecated/plugin" unless Guard::Config.new.strict?

module Guard
  class Plugin
    Deprecated::Plugin.add_deprecated(self) unless Guard::Config.new.strict?
  end
end
