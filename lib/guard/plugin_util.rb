module Guard

  # This class contains useful methods to fetch all the Guard plugins names,
  # initialize a plugin, get its location, returns its class name and add its
  # template to the Guardfile.
  #
  class PluginUtil

    require 'guard/ui'

    attr_accessor :name

    class << self

      # Returns a list of Guard plugin Gem names installed locally.
      #
      # @return [Array<String>] a list of Guard plugin gem names
      #
      def plugin_names
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
        end.map { |x| x.name.sub(/^guard-/, '') }
      end

    end

    # Initializes a new Guard::PluginUtil object.
    #
    # @param [String] name the name of the Guard plugin
    #
    def initialize(name)
      @name = name.to_s
    end

    # Initialize a new Guard::Plugin with the given options. This methods
    # handles plugins that inherit from the deprecated Guard::Guard class
    # as well as plugins that inherit from Guard::Plugin.
    #
    def initialize_plugin(options)
      if plugin_class.superclass == ::Guard::Guard
        plugin_class.new(options.delete(:watchers), options)
      else
        plugin_class.new(options)
      end
    end

    # Locates a path to a Guard plugin gem.
    #
    # @return [String] the full path to the Guard gem
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
      options = { :fail_gracefully => false }.merge(options)

      try_require = false
      begin
        require "guard/#{ name.downcase }" if try_require

        @plugin_class ||= ::Guard.const_get(plugin_constant)
      rescue TypeError
        if try_require
          ::Guard::UI.error "Could not find class Guard::#{ constant_name.capitalize }"
        else
          try_require = true
          retry
        end
      rescue LoadError => loadError
        unless options[:fail_gracefully]
          ::Guard::UI.error "Could not load 'guard/#{ name.downcase }' or find class Guard::#{ constant_name.capitalize }"
          ::Guard::UI.error loadError.to_s
        end
      end
    end

    # Adds a plugin's template to the Guardfile.
    #
    def add_to_guardfile
      if ::Guard::Dsl.guardfile_include?(name)
        ::Guard::UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read('Guardfile')
        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts('')
          f.puts(template)
        end

        ::Guard::UI.info "#{ name } guard added to Guardfile, feel free to edit it"
      end
    end

    private

    def plugin_constant
      @plugin_constant ||= begin
        ::Guard.constants.find { |c| c.to_s == constant_name } ||
        ::Guard.constants.find { |c| c.to_s.downcase == constant_name.downcase }
      end
    end

    def constant_name
      @constant_name ||= name.gsub(/\/(.?)/) { "::#{ $1.upcase }" }.gsub(/(?:^|[_-])(.)/) { $1.upcase }
    end

    # Specify the source for the Guardfile template.
    # Each Guard plugin can redefine this method to add its own logic.
    #
    def template
      @template ||= File.read("#{ plugin_location }/lib/guard/#{ name }/templates/Guardfile")
    end

  end
end