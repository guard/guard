# frozen_string_literal: true

require "guard/dsl"
require "guard/dsl_reader"

module Guard
  module Guardfile
    # This class is responsible for evaluating the Guardfile. It delegates to
    # Guard::Dsl for the actual objects generation from the Guardfile content.
    #
    # @see Guard::Dsl
    #
    class Evaluator
      DEFAULT_GUARDFILES = %w(
        guardfile.rb
        Guardfile
        ~/.Guardfile
      ).freeze

      # @private
      ERROR_NO_GUARDFILE = "No Guardfile found,"\
        " please create one with `guard init`."

      attr_reader :guardfile_path

      # @private
      ERROR_NO_PLUGINS = "No Guard plugins found in Guardfile,"\
        " please add at least one."

      # @private
      class Error < RuntimeError
      end

      class NoGuardfileError < Error
      end

      class NoCustomGuardfile < Error
      end

      class NoPluginsError < Error
      end

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option opts [String] guardfile the path to a valid Guardfile
      # content of a valid Guardfile
      #
      def initialize(engine)
        @engine = engine
        @guardfile_path = nil
        @opts = engine.session.evaluator_options
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @example Programmatically evaluate a Guardfile
      #   engine = Guard::Engine.new
      #   Guard::Guardfile::Evaluator.new(engine).evaluate
      #
      # @example Programmatically evaluate a Guardfile with a custom Guardfile
      # path
      #
      #   options = { guardfile: '/Users/guardfile/MyAwesomeGuardfile' }
      #   engine = Guard::Engine.new(options)
      #   Guard::Guardfile::Evaluator.new(engine).evaluate
      #
      # @example Programmatically evaluate a Guardfile with an inline Guardfile
      #
      #   options = { inline: 'guard :rspec' }
      #   engine = Guard::Engine.new(options)
      #   Guard::Guardfile::Evaluator.new(engine).evaluate
      #
      def evaluate
        raise NoPluginsError, ERROR_NO_PLUGINS unless /guard/m =~ guardfile_contents

        Dsl.new(engine).evaluate(guardfile_contents, guardfile_path || "", 1)
      end

      # Tests if the current `Guardfile` contains a specific Guard plugin.
      #
      # @example Programmatically test if a Guardfile contains a specific Guard
      # plugin
      #
      #   File.read('Guardfile')
      #   => "guard :rspec"
      #
      #   Guard::Guardfile::Evaluator.new(engine).guardfile_include?('rspec')
      #   => true
      #
      # @param [String] plugin_name the name of the Guard
      # @return [Boolean] whether the Guard plugin has been declared
      #
      def guardfile_include?(plugin_name)
        reader = DslReader.new(engine)
        reader.evaluate(guardfile_contents, guardfile_path || "", 1)
        reader.plugin_names.include?(plugin_name)
      end

      def custom?
        !!opts[:guardfile]
      end

      def inline?
        !!opts[:inline]
      end

      def guardfile_contents
        @guardfile_contents ||= begin
          _use_inline || _use_custom || _use_default

          [@contents, _user_config].compact.join("\n")
        end
      end

      private

      attr_reader :engine, :opts

      def _use_inline
        return unless inline?

        @contents = opts[:inline]
      end

      def _use_custom
        return unless custom?

        @guardfile_path, @contents = _read(Pathname.new(opts[:guardfile]))
      rescue Errno::ENOENT
        fail NoCustomGuardfile, "No Guardfile exists at #{@guardfile_path}."
      end

      def _use_default
        DEFAULT_GUARDFILES.each do |guardfile|
          @guardfile_path, @contents = _read(guardfile)
          break
        rescue Errno::ENOENT
          if guardfile == DEFAULT_GUARDFILES.last
            fail NoGuardfileError, ERROR_NO_GUARDFILE
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
