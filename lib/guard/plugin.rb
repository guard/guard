require "guard"
require "guard/api"

module Guard
  class Plugin
    include Guard::API

    def initialize(*)
      super

      plugin_util = PluginUtil.new(name)
      plugin_file = "#{plugin_util.plugin_location}/lib/guard/#{name}.rb"
      msg = <<-MSG
      Inherithing from Guard::Plugin is now deprecated.

      Guard has choosen to sanitize its architecture, you can conform to it with
      the following steps:

      - Make your gem dependent on `s.add_dependency "guard-compat", "~> 1.1"`in
        your gemspec
      - Make Guard::#{title} a module
      - Add `require 'guard/compat/plugin'` at the beginning of #{plugin_file}
      - Create a new Guard::#{title}::Plugin class that `include Compat::API`

      For testing your plugin, you should follow the guard-compat guidelines at
      https://github.com/guard/guard-compat#important.
      MSG
      UI.deprecation(msg)
    end
  end
end
