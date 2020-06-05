# frozen_string_literal: true

require "guard/ui"
require "guard/plugin_util"

module Guard
  module Guardfile
    # This class is responsible for generating the Guardfile and adding Guard'
    # plugins' templates into it.
    #
    # @see Guard::CLI
    #
    class Generator
      # @private
      INFO_TEMPLATE_ADDED =
        "%s template added to Guardfile, feel free to edit it"

      # @private
      # The Guardfile template for `guard init`
      GUARDFILE_TEMPLATE = File.expand_path(
        "../../guard/templates/Guardfile",
        __dir__
      )

      # The location of user defined templates
      begin
        HOME_TEMPLATES = Pathname.new("~/.guard/templates").expand_path
      rescue ArgumentError
        # home isn't defined.  Set to the root of the drive.  Trust that there
        # won't be user defined templates there
        HOME_TEMPLATES = Pathname.new("/").expand_path
      end

      # @private
      class Error < RuntimeError
      end

      class NoSuchPlugin < Error
        attr_reader :plugin_name, :class_name

        def initialize(plugin_name)
          @plugin_name = plugin_name
          @class_name = plugin_name.delete("-").capitalize
        end

        def message
          "Could not load 'guard/#{plugin_name}'"\
          " or '~/.guard/templates/#{plugin_name}'"\
          " or find class Guard::#{class_name}\n"
        end
      end

      def initialize(engine)
        @engine = engine
      end

      # Creates the initial Guardfile template when it does not
      # already exist.
      #
      # @see Guard::CLI#init
      #
      def create_guardfile
        path = Pathname.new("Guardfile").expand_path
        if path.exist?
          UI.error("Guardfile already exists at #{path}")
          abort
        end

        UI.info("Writing new Guardfile to #{path}")
        FileUtils.cp(GUARDFILE_TEMPLATE, path.to_s)
      end

      # Adds the Guardfile template of a Guard plugin to an existing Guardfile.
      #
      # @see Guard::CLI#init
      #
      def initialize_template(plugin_name)
        guardfile = Pathname.new("Guardfile")
        plugin_util = PluginUtil.new(engine, plugin_name)

        if plugin_util.valid?
          begin
            plugin_util.add_to_guardfile
          rescue Errno::ENOENT => e
            UI.error("Found class #{plugin_util.plugin_class} but loading its template failed.")
            UI.error("Error is: #{e}")
            return
          end
          return
        end

        template_code = (HOME_TEMPLATES + plugin_name).read
        guardfile.binwrite(format("\n%<template>s\n", template: template_code), open_args: ["a"])

        UI.info(format(INFO_TEMPLATE_ADDED, plugin_name))
      rescue Errno::ENOENT
        fail NoSuchPlugin, plugin_name.downcase
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

      attr_reader :engine
    end
  end
end
