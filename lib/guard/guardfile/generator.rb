module Guard
  module Guardfile

    # This class is responsible for generating the Guardfile and adding Guard'
    # plugins' templates into it.
    #
    # @see Guard::CLI
    #
    class Generator

      require 'guard'
      require 'guard/ui'

      attr_reader :options

      # The Guardfile template for `guard init`
      GUARDFILE_TEMPLATE = File.expand_path('../../../guard/templates/Guardfile', __FILE__)

      # The location of user defined templates
      begin
        HOME_TEMPLATES = File.expand_path('~/.guard/templates')
      rescue ArgumentError => e
        # home isn't defined.  Set to the root of the drive.  Trust that there won't be user defined templates there
        HOME_TEMPLATES = File.expand_path('/')
      end

      # Initialize a new `Guard::Guardfile::Generator` object.
      #
      # @param [Hash] options The options for creating a Guardfile
      # @option options [Boolean] :abort_on_existence Whether to abort or not
      #   when a Guardfile already exists
      #
      def initialize(options = {})
        @options = options
      end

      # Creates the initial Guardfile template when it does not
      # already exist.
      #
      # @see Guard::CLI#init
      #
      def create_guardfile
        if !File.exist?('Guardfile')
          ::Guard::UI.info "Writing new Guardfile to #{ Dir.pwd }/Guardfile"
          FileUtils.cp(GUARDFILE_TEMPLATE, 'Guardfile')
        elsif options[:abort_on_existence]
          ::Guard::UI.error "Guardfile already exists at #{ Dir.pwd }/Guardfile"
          abort
        end
      end

      # Adds the Guardfile template of a Guard plugin to an existing Guardfile.
      #
      # @see Guard::CLI#init
      #
      # @param [String] plugin_name the name of the Guard plugin or template to
      #   initialize
      #
      def initialize_template(plugin_name)
        plugin_util = ::Guard::PluginUtil.new(plugin_name)
        if plugin_util.plugin_class(fail_gracefully: true)
          plugin_util.add_to_guardfile

          @options[:guardfile] = File.read('Guardfile') if File.exists?('Guardfile')

        elsif File.exist?(File.join(HOME_TEMPLATES, plugin_name))
          content = File.read('Guardfile')

          File.open('Guardfile', 'wb') do |f|
            f.puts(content)
            f.puts('')
            f.puts(File.read(File.join(HOME_TEMPLATES, plugin_name)))
          end

          ::Guard::UI.info "#{ plugin_name } template added to Guardfile, feel free to edit it"
        else
          const_name = plugin_name.downcase.gsub('-', '')
          UI.error "Could not load 'guard/#{ plugin_name.downcase }' or '~/.guard/templates/#{ plugin_name.downcase }' or find class Guard::#{ const_name.capitalize }"
        end
      end

      # Adds the templates of all installed Guard implementations to an
      # existing Guardfile.
      #
      # @see Guard::CLI#init
      #
      def initialize_all_templates
        ::Guard::PluginUtil.plugin_names.each { |g| initialize_template(g) }
      end

    end

  end
end
