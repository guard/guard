require "guard/config"
require "guard/options"
require "guard/plugin"

# TODO: this class shouldn't use notify directly
require "guard/notifier"

require "guard/dsl"
require "guard/metadata"

require "guard/deprecated/evaluator" unless Guard::Config.new.strict?

module Guard
  module Guardfile
    # This class is responsible for evaluating the Guardfile. It delegates to
    # Guard::Dsl for the actual objects generation from the Guardfile content.
    #
    # @see Guard::Dsl
    #
    class Evaluator
      Deprecated::Evaluator.add_deprecated(self) unless Config.new.strict?

      attr_reader :options, :guardfile_path

      def guardfile_source
        @source
      end

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option opts [String] guardfile the path to a valid Guardfile
      # @option opts [String] guardfile_contents a string representing the
      # content of a valid Guardfile
      #
      def initialize(opts = {})
        @evaluated = false
        @source = nil
        @guardfile_path = nil

        valid_options = opts.select do |k, _|
          [:guardfile, :guardfile_contents].include?(k.to_sym)
        end

        @options = Options.new(valid_options)
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @example Programmatically evaluate a Guardfile
      #   Guard::Guardfile::Evaluator.new.evaluate_guardfile
      #
      # @example Programmatically evaluate a Guardfile with a custom Guardfile
      # path
      #
      #   options = { guardfile: '/Users/guardfile/MyAwesomeGuardfile' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
      #
      # @example Programmatically evaluate a Guardfile with an inline Guardfile
      #
      #   options = { guardfile_contents: 'guard :rspec' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
      #
      def evaluate
        _fetch_guardfile_contents
        _instance_eval_guardfile(guardfile_contents)

        Guard.add_builtin_plugins(guardfile_path)
      end

      def inline?
        @source == :inline
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
      def guardfile_include?(plugin_name)
        /^\s*guard\s*\(?\s*['":]#{ plugin_name }['"]?/.
          match _guardfile_contents_without_user_config
      end

      # Gets the content of the `Guardfile` concatenated with the global
      # user configuration file.
      #
      # @example Programmatically get the content of the current Guardfile
      #   Guard::Guardfile::Evaluator.new.guardfile_contents
      #   => "guard :rspec"
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents
        config = File.read(_user_config_path) if File.exist?(_user_config_path)
        [_guardfile_contents_without_user_config, config].compact.join("\n")
      end

      private

      def _guardfile_contents_without_user_config
        fail "BUG: no data - Guardfile wasn't evaluated" unless @evaluated
        @guardfile_contents || ""
      end

      def _instance_eval_guardfile(contents)
        ::Guard::Dsl.new.instance_eval(contents, @guardfile_path || "", 1)
      rescue => ex
        ::Guard::UI.error "Invalid Guardfile, original error is:\n#{ $! }"
        raise ex
      end

      def _fetch_guardfile_contents
        _use_inline || _use_provided || _use_default
        @evaluated = true

        return if _guardfile_contents_usable?
        UI.error "No Guard plugins found in Guardfile,"\
          " please add at least one."
      end

      def _use_inline
        source_from_option = @source.nil? && options[:guardfile_contents]
        inline = @source == :inline

        return false unless (source_from_option) || inline

        @source   = :inline
        @guardfile_contents = options[:guardfile_contents]

        ::Guard::UI.info "Using inline Guardfile."
        true
      end

      def _use_provided
        source_from_file = @source.nil? && options[:guardfile]
        return false unless source_from_file || (@source == :custom)

        @source = :custom

        options[:guardfile] = File.expand_path(options[:guardfile])
        if File.exist?(options[:guardfile])
          _read(options[:guardfile])
          ::Guard::UI.info "Using Guardfile at #{ options[:guardfile] }."
          true
        else
          ::Guard::UI.error "No Guardfile exists at #{ options[:guardfile] }."
          exit 1
        end

        true
      end

      def _use_default
        if guardfile_path = _find_default_guardfile
          @source = :default
          _read(guardfile_path)
        else
          ::Guard::UI.error \
            "No Guardfile found, please create one with `guard init`."
          exit 1
        end
      end

      def _find_default_guardfile
        [_local_guardfile_path, _home_guardfile_path].detect do |path|
          File.exist?(path)
        end
      end

      def _read(guardfile_path)
        @guardfile_path     = guardfile_path
        @guardfile_contents = File.read(guardfile_path)
      rescue => ex
        ::Guard::UI.error "Error reading file #{ guardfile_path }:"
        ::Guard::UI.error ex.inspect
        ::Guard::UI.error ex.backtrace
        exit 1
      end

      def _guardfile_contents_usable?
        guardfile_contents && guardfile_contents =~ /guard/m
      end

      def _local_guardfile_path
        File.expand_path(File.join(Dir.pwd, "Guardfile"))
      end

      def _home_guardfile_path
        File.expand_path(File.join("~", ".Guardfile"))
      end

      def _user_config_path
        File.expand_path(File.join("~", ".guard.rb"))
      end
    end
  end
end
