# frozen_string_literal: true

require "guard/dsl"
require "guard/dsl"

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
      EVALUATOR_OPTIONS = %i[guardfile inline].freeze

      # @private
      ERROR_NO_GUARDFILE = "No Guardfile found,"\
        " please create one with `guard init`."

      attr_reader :options, :guardfile_path

      # @private
      class Error < RuntimeError
      end

      class NoGuardfileError < Error
      end

      class NoCustomGuardfile < Error
      end

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option options [String] guardfile the path to a valid Guardfile
      # content of a valid Guardfile
      #
      def initialize(options = {})
        @guardfile_path = nil
        @options = Options.new(options.slice(*Guard::Guardfile::Evaluator::EVALUATOR_OPTIONS))
        @dsl = Dsl.new
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @return Guard::Guardfile::Result
      #
      def evaluate
        @evaluate ||= begin
          dsl.evaluate(guardfile_contents, guardfile_path || "", 1)
          dsl.result
        end
      end

      # Tests if the current `Guardfile` contains a specific Guard plugin.
      #
      # @example Programmatically test if a Guardfile contains a specific Guard
      # plugin
      #
      #   File.read('Guardfile')
      #   => "guard :rspec"
      #
      #   Guard::Guardfile::Evaluator.new.guardfile_include?('rspec')
      #   => true
      #
      # @param [String] plugin_name the name of the Guard
      # @return [Boolean] whether the Guard plugin has been declared
      #
      def guardfile_include?(plugin_name)
        evaluate.plugin_names.include?(plugin_name.to_sym)
      end

      def custom?
        !!options[:guardfile]
      end

      def inline?
        !!options[:inline]
      end

      def guardfile_contents
        @guardfile_contents ||= begin
          _use_inline || _use_custom || _use_default

          [@contents, _user_config].compact.join("\n")
        end
      end

      private

      attr_reader :dsl

      def _use_inline
        return unless inline?

        @contents = options[:inline]
      end

      def _use_custom
        return unless custom?

        @guardfile_path, @contents = _read(Pathname.new(options[:guardfile]))
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
