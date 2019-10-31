# frozen_string_literal: true

require "guard/config"
require "guard/deprecated/evaluator" unless Guard::Config.new.strict?

require "guard/dsl"
require "guard/dsl_reader"

module Guard
  module Guardfile
    # This class is responsible for evaluating the Guardfile. It delegates to
    # Guard::Dsl for the actual objects generation from the Guardfile content.
    #
    # @see Guard::Dsl
    #
    # TODO: rename this to a Locator or Loader or something
    class Evaluator
      Deprecated::Evaluator.add_deprecated(self) unless Config.new.strict?

      DEFAULT_GUARDFILES = %w(
        guardfile.rb
        Guardfile
        ~/.Guardfile
      ).freeze

      ERROR_NO_GUARDFILE = "No Guardfile found,"\
        " please create one with `guard init`."

      attr_reader :guardfile_path

      ERROR_NO_PLUGINS = "No Guard plugins found in Guardfile,"\
        " please add at least one."

      class Error < RuntimeError
      end

      class NoGuardfileError < Error
      end

      class NoCustomGuardfile < Error
      end

      class NoPluginsError < Error
      end

      def self.from_deprecated(opts)
        opts.dup.tap do |hash|
          hash[:contents] = hash.delete(:guardfile_contents) if hash.key?(:guardfile_contents)
        end
      end

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option opts [String] guardfile the path to a valid Guardfile
      # @option opts [String] contents a string representing the
      # content of a valid Guardfile
      #
      def initialize(opts = {})
        @guardfile_path = nil
        @opts = self.class.from_deprecated(opts)
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @example Programmatically evaluate a Guardfile
      #   Guard::Guardfile::Evaluator.new.evaluate
      #
      # @example Programmatically evaluate a Guardfile with a custom Guardfile
      # path
      #
      #   options = { guardfile: '/Users/guardfile/MyAwesomeGuardfile' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate
      #
      # @example Programmatically evaluate a Guardfile with an inline Guardfile
      #
      #   options = { contents: 'guard :rspec' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate
      #
      def evaluate
        _use_inline || _use_custom || _use_default

        contents = guardfile_contents
        fail NoPluginsError, ERROR_NO_PLUGINS unless /guard/m =~ contents

        Dsl.new.evaluate(contents, guardfile_path || "", 1)
      end

      # Tests if the current `Guardfile` contains a specific Guard plugin.
      #
      # @example Programmatically test if a Guardfile contains a specific Guard
      # plugin
      #
      #   File.read('Guardfile')
      #   => "guard :rspec"
      #
      #   Guard::Guardfile::Evaluator.new.guardfile_include?('rspec)
      #   => true
      #
      # @param [String] plugin_name the name of the Guard
      # @return [Boolean] whether the Guard plugin has been declared
      #
      # TODO: rename this method to it matches RSpec examples better
      def guardfile_include?(plugin_name)
        reader = DslReader.new
        reader.evaluate(@contents, guardfile_path || "", 1)
        reader.plugin_names.include?(plugin_name)
      end

      def custom?
        opts.key?(:guardfile)
      end

      def inline?
        opts.key?(:contents)
      end

      def guardfile_contents
        [@contents, _user_config].compact.join("\n")
      end

      private

      attr_reader :opts

      def _use_inline
        return unless inline?

        @contents = opts[:contents]
      end

      def _use_custom
        return unless custom?

        @guardfile_path, @contents = _read(Pathname.new(opts[:guardfile]))
      rescue Errno::ENOENT
        fail NoCustomGuardfile, "No Guardfile exists at #{@guardfile_path}."
      end

      def _use_default
        DEFAULT_GUARDFILES.each do |guardfile|
          begin
            @guardfile_path, @contents = _read(guardfile)
            break
          rescue Errno::ENOENT
            if guardfile == DEFAULT_GUARDFILES.last
              fail NoGuardfileError, ERROR_NO_GUARDFILE
            end
          end
        end
      end

      def _read(path)
        full_path = Pathname.new(path.to_s).expand_path
        [full_path, full_path.read]
      rescue Errno::ENOENT
        fail
      rescue SystemCallError => e
        UI.error "Error reading file #{full_path}:"
        UI.error e.inspect
        UI.error e.backtrace
        abort
      end

      def _user_config
        @_user_config ||=
          begin
            Pathname.new("~/.guard.rb").expand_path.read
          rescue Errno::ENOENT
            nil
          end
      end
    end
  end
end
