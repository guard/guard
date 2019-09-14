require "guard/api"

module Guard
  # @deprecated Every method in this module is deprecated
  module Deprecated
    module Plugin
      def self.add_deprecated(klass)
        # This include is needed here to have the correct ancestors chain, i.e.:
        # [Guard::Foo, Guard::Plugin, Guard::Deprecated::Plugin, Guard::API, Object ...]
        self.include(::Guard::API)
        # This extend is needed here because the one from API is extending
        # Guard::Deprecated::Plugin instead of klass.
        klass.send(:extend, ::Guard::API::ClassMethods)
        klass.send(:include, self)
      end

      INHERITHING_FROM_PLUGIN = <<-EOS.gsub(/^\s*/, "")
      Inherithing from Guard::Plugin is now deprecated.

      Guard has choosen to sanitize its architecture, you can conform to it with
      the following steps:

      - Make your gem dependent on `s.add_dependency "guard-compat", "~> 1.1"`in
        your gemspec
      - Make Guard::%s a module
      - Add `require 'guard/compat/plugin'` at the beginning of %s
      - Create a new Guard::%s::Plugin class that `include Compat::API`
      - The new constructor signature is `def initialize(engine:, options:)`

      For testing your plugin, you should follow the guard-compat guidelines at
      https://github.com/guard/guard-compat#important.
      EOS

      # Guard::Plugin constructor was accepting a single options hash
      def initialize(options = {})
        plugin_util = PluginUtil.new(engine: options[:engine], name: name)
        plugin_file = "#{plugin_util.plugin_location}/lib/guard/#{name}.rb"

        ::Guard::UI.deprecation(format(INHERITHING_FROM_PLUGIN, title, plugin_file, title))

        super(engine: options.delete(:engine), options: options.fetch(:options, {}))

        # Replace options with options[:options] so that plugin constructors
        # that inherits from Guard::Plugin can still override it.
        options.replace(options.delete(:options) { {} })
      end
    end
  end
end
