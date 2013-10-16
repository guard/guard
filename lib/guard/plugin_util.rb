require 'guard/ui'

module Guard

  # This class contains useful methods to:
  #
  # * Fetch all the Guard plugins names;
  # * Initialize a plugin, get its location;
  # * Return its class name;
  # * Add its template to the Guardfile.
  #
  class PluginUtil

    attr_accessor :name

    # Returns a list of Guard plugin Gem names installed locally.
    #
    # @return [Array<String>] a list of Guard plugin gem names
    #
    def self.plugin_names
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_all.select do |x|
          if x.name =~ /^guard-/
            true
          elsif x.name != 'guard'
            guard_plugin_path = File.join(x.full_gem_path, "lib/guard/#{ x.name }.rb")
            File.exists?( guard_plugin_path )
          end
        end
      else
        Gem.source_index.find_name(/^guard-/)
      end.map { |x| x.name.sub(/^guard-/, '') }.uniq
    end

    # Initializes a new `Guard::PluginUtil` object.
    #
    # @param [String] name the name of the Guard plugin
    #
    def initialize(name)
      @name = name.to_s.sub(/^guard-/, '')
    end

    # Initializes a new `Guard::Plugin` with the given `options` hash. This
    # methods handles plugins that inherit from the deprecated `Guard::Guard`
    # class as well as plugins that inherit from `Guard::Plugin`.
    #
    # @see Guard::Plugin
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    # @return [Guard::Plugin] the initialized plugin
    # @return [Guard::Guard] the initialized plugin. This return type is
    #   deprecated and the plugin's maintainer should update it to be
    #   compatible with Guard 2.0. For more information on how to upgrade for
    #   Guard 2.0, please head over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0
    #
    def initialize_plugin(options)
      if plugin_class.superclass.to_s == 'Guard::Guard'
        plugin_class.new(options.delete(:watchers), options)
      else
        plugin_class.new(options)
      end
    end

    # Locates a path to a Guard plugin gem.
    #
    # @return [String] the full path to the plugin gem
    #
    def plugin_location
      @plugin_location ||= begin
        if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
          Gem::Specification.find_by_name("guard-#{ name }").full_gem_path
        else
          Gem.source_index.find_name("guard-#{ name }").last.full_gem_path
        end
      end
    rescue
      ::Guard::UI.error "Could not find 'guard-#{ name }' gem path."
    end

    # Tries to load the Guard plugin main class. This transforms the supplied
    # plugin name into a class name:
    #
    # * `guardname` will become `Guard::Guardname`
    # * `dashed-guard-name` will become `Guard::DashedGuardName`
    # * `underscore_guard_name` will become `Guard::UnderscoreGuardName`
    #
    # When no class is found with the strict case sensitive rules, another
    # try is made to locate the class without matching case:
    #
    # * `rspec` will find a class `Guard::RSpec`
    #
    # @option options [Boolean] fail_gracefully whether error messages should not be printed
    # @return [Class, nil] the loaded class
    #
    def plugin_class(options = {})
      options = { fail_gracefully: false }.merge(options)

      try_require = false
      begin
        require "guard/#{ name.downcase }" if try_require

        @plugin_class ||= ::Guard.const_get(_plugin_constant)
      rescue TypeError => typeError
        if try_require
          ::Guard::UI.error "Could not find class Guard::#{ _constant_name }"
          ::Guard::UI.error typeError.backtrace.join("\n")
        else
          try_require = true
          retry
        end
      rescue LoadError => loadError
        unless options[:fail_gracefully]
          ::Guard::UI.error "Could not load 'guard/#{ name.downcase }' or find class Guard::#{ _constant_name }"
          ::Guard::UI.error loadError.backtrace.join("\n")
        end
      end
    end

    # Adds a plugin's template to the Guardfile.
    #
    def add_to_guardfile
      if ::Guard.evaluator.guardfile_include?(name)
        ::Guard::UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read('Guardfile')
        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts('')
          f.puts(plugin_class.template(plugin_location))
        end

        ::Guard::UI.info "#{ name } guard added to Guardfile, feel free to edit it"
      end
    end

    private

    # Returns the constant for the current plugin.
    #
    # @example Returns the constant for a plugin
    #   > Guard::PluginUtil.new('rspec').send(:_plugin_constant)
    #   => Guard::RSpec
    #
    def _plugin_constant
      @_plugin_constant ||= ::Guard.constants.find { |c| c.to_s.downcase == _constant_name.downcase }
    end

    # Guesses the most probable name for the current plugin based on its name.
    #
    # @example Returns the most probable name for a plugin
    #   > Guard::PluginUtil.new('rspec').send(:_constant_name)
    #   => "Rspec"
    #
    def _constant_name
      @_constant_name ||= name.gsub(/\/(.?)/) { "::#{ $1.upcase }" }.gsub(/(?:^|[_-])(.)/) { $1.upcase }
    end

  end
end
