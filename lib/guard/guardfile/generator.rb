require "guard/ui"
require "guard/plugin_util"

# Add Pathname#binwrite to 1.9.3
unless Pathname.instance_methods.include?(:binwrite)
  class Pathname
    def binwrite(*args)
      IO.binwrite(to_s, *args)
    end
  end
end

module Guard
  module Guardfile
    # This class is responsible for generating the Guardfile and adding Guard'
    # plugins' templates into it.
    #
    # @see Guard::CLI
    #
    class Generator
      require "guard"
      require "guard/ui"

      INFO_TEMPLATE_ADDED =
        "%s template added to Guardfile, feel free to edit it"

      # The Guardfile template for `guard init`
      GUARDFILE_TEMPLATE = File.expand_path(
        "../../../guard/templates/Guardfile",
        __FILE__)

      # The location of user defined templates
      begin
        HOME_TEMPLATES = Pathname("~/.guard/templates").expand_path
      rescue ArgumentError
        # home isn't defined.  Set to the root of the drive.  Trust that there
        # won't be user defined templates there
        HOME_TEMPLATES = Pathname("/").expand_path
      end

      # Creates the initial Guardfile template when it does not
      # already exist.
      #
      # @see Guard::CLI#init
      #
      def create_guardfile
        path = Pathname("Guardfile").expand_path
        if path.exist?
          contents = path.read
          if contents.empty?
            _ui(:info, "Writing to existing empty Guardfile at #{path}")
            FileUtils.cp(GUARDFILE_TEMPLATE, path.to_s)
          else
            _ui(:error, "Guardfile already exists at #{path}")
            abort
          end
        end

        _ui(:info, "Writing new Guardfile to #{path}")
        FileUtils.cp(GUARDFILE_TEMPLATE, path.to_s)
      end

      # Adds the Guardfile template of a Guard plugin to an existing Guardfile.
      #
      # @see Guard::CLI#init
      #
      # @param [String] plugin_name the name of the Guard plugin or template to
      #   initialize
      #
      def initialize_template(plugin_name)
        guardfile = Pathname("Guardfile")

        plugin_util = PluginUtil.new(plugin_name)
        # TODO: change to "valid?" method
        if plugin_util.plugin_class(fail_gracefully: true)
          plugin_util.add_to_guardfile
          return
        end

        template_code = (HOME_TEMPLATES + plugin_name).read
        guardfile.binwrite(format("\n%s\n", template_code), open_args: ["a"])

        _ui(:info, format(INFO_TEMPLATE_ADDED, plugin_name))

      rescue Errno::ENOENT => error

        name = plugin_name.downcase
        class_name = name.gsub("-", "").capitalize
        _ui(:error, "Could not load 'guard/#{name}'"\
            " or '~/.guard/templates/#{name}'"\
            " or find class Guard::#{class_name}")
        _ui(:error, "Error is: #{error}")
      end

      # Adds the templates of all installed Guard implementations to an
      # existing Guardfile.
      #
      # @see Guard::CLI#init
      #
      def initialize_all_templates
        PluginUtil.plugin_names.each { |g| initialize_template(g) }
      end

      private

      def _ui(*args)
        UI.send(*args)
      end
    end
  end
end
