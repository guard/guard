module Guard
  module Guardfile

    # This class is responsible for evaluating the Guardfile. It delegates
    # to Guard::Dsl for the actual objects generation from the Guardfile content.
    #
    # @see Guard::Dsl
    #
    class Evaluator

      attr_reader :options

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option opts [String] guardfile the path to a valid Guardfile
      # @option opts [String] guardfile_contents a string representing the content of a valid Guardfile
      #
      def initialize(opts = {})
        @options = ::Guard::Options.new([:guardfile, :guardfile_contents].reduce({}) { |h, key| h[key] = opts[key]; h })
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @example Programmatically evaluate a Guardfile
      #   Guard::Guardfile::Evaluator.new.evaluate_guardfile
      #
      # @example Programmatically evaluate a Guardfile with a custom Guardfile path
      #   Guard::Guardfile::Evaluator.new(guardfile: '/Users/guardfile/MyAwesomeGuardfile').evaluate_guardfile
      #
      # @example Programmatically evaluate a Guardfile with an inline Guardfile
      #   Guard::Guardfile::Evaluator.new(guardfile_contents: 'guard :rspec').evaluate_guardfile
      #
      def evaluate_guardfile
        _fetch_guardfile_contents
        _instance_eval_guardfile(guardfile_contents)
      end

      # Re-evaluates the `Guardfile` to update
      # the current Guard configuration.
      #
      def reevaluate_guardfile
        _before_reevaluate_guardfile
        evaluate_guardfile
        _after_reevaluate_guardfile
      end

      # Tests if the current `Guardfile` contains a specific Guard plugin.
      #
      # @example Programmatically test if a Guardfile contains a specific Guard plugin
      #   File.read('Guardfile')
      #   #=> "guard :rspec"
      #
      #   Guard::Guardfile::Evaluator.new.guardfile_include?('rspec)
      #   #=> true
      #
      # @param [String] plugin_name the name of the Guard
      # @return [Boolean] whether the Guard plugin has been declared
      #
      def guardfile_include?(plugin_name)
        _guardfile_contents_without_user_config.match(/^guard\s*\(?\s*['":]#{ plugin_name }['"]?/)
      end

      # Gets the file path to the project `Guardfile`.
      #
      # @example Gets the path of the currently evaluated Guardfile
      #   Dir.pwd
      #   #=> "/Users/remy/Code/github/guard"
      #
      #   evaluator = Guard::Guardfile::Evaluator.new
      #   evaluator.evaluate_guardfile
      #   #=> nil
      #
      #   evaluator.guardfile_path
      #   #=> "/Users/remy/Code/github/guard/Guardfile"
      #
      # @example Gets the "path" of an inline Guardfile
      #   > Guard::Guardfile::Evaluator.new(guardfile_contents: 'guard :rspec').evaluate_guardfile
      #   => nil
      #
      #   > Guard::Guardfile::Evaluator.new.guardfile_path
      #   => "Inline Guardfile"
      #
      # @return [String] the path to the Guardfile or 'Inline Guardfile' if
      #   the Guardfile has been specified via the `:guardfile_contents` option.
      #
      def guardfile_path
        options.guardfile_path || ''
      end

      # Gets the content of the `Guardfile` concatenated with the global
      # user configuration file.
      #
      # @example Programmatically get the content of the current Guardfile
      #   Guard::Guardfile::Evaluator.new.guardfile_contents
      #   #=> "guard :rspec"
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents
        config = File.read(_user_config_path) if File.exist?(_user_config_path)
        [_guardfile_contents_without_user_config, config].compact.join("\n")
      end

      private

      # Gets the default path of the `Guardfile`. This returns the `Guardfile`
      # from the current directory when existing, or the global `~/.Guardfile`.
      #
      # @return [String] the path to the Guardfile
      #
      def _guardfile_default_path
        File.exist?(_local_guardfile_path) ? _local_guardfile_path : _home_guardfile_path
      end

      # Gets the content of the `Guardfile`.
      #
      # @return [String] the Guardfile content
      #
      def _guardfile_contents_without_user_config
        options.guardfile_contents || ''
      end

      # Evaluates the content of the `Guardfile`.
      #
      # @param [String] contents the content to evaluate.
      #
      def _instance_eval_guardfile(contents)
        ::Guard::Dsl.new.instance_eval(contents, options.guardfile_path, 1)
      rescue => ex
        ::Guard::UI.error "Invalid Guardfile, original error is:\n#{ $! }"
        raise ex
      end

      # Gets the content to evaluate and stores it into
      # the options as `:guardfile_contents`.
      #
      def _fetch_guardfile_contents
        if options.guardfile_contents
          ::Guard::UI.info 'Using inline Guardfile.'
          options.guardfile_path = 'Inline Guardfile'

        elsif options.guardfile
          if File.exist?(options.guardfile)
            _read_guardfile(options.guardfile)
            ::Guard::UI.info "Using Guardfile at #{ options.guardfile }."
          else
            ::Guard::UI.error "No Guardfile exists at #{ options.guardfile }."
            exit 1
          end

        else
          if File.exist?(_guardfile_default_path)
            _read_guardfile(_guardfile_default_path)
          else
            ::Guard::UI.error 'No Guardfile found, please create one with `guard init`.'
            exit 1
          end
        end

        unless _guardfile_contents_usable?
          ::Guard::UI.error 'No Guard plugins found in Guardfile, please add at least one.'
        end
      end

      # Reads the current `Guardfile` content.
      #
      # @param [String] guardfile_path the path to the Guardfile
      #
      def _read_guardfile(guardfile_path)
        options.guardfile_path     = guardfile_path
        options.guardfile_contents = File.read(guardfile_path)
      rescue => ex
        ::Guard::UI.error ex.inspect
        ::Guard::UI.error("Error reading file #{ guardfile_path }")
        exit 1
      end

      # Stops Guard and clear internal state
      # before the Guardfile will be re-evaluated.
      #
      def _before_reevaluate_guardfile
        ::Guard.runner.run(:stop)
        ::Guard.reset_groups
        ::Guard.reset_plugins
        ::Guard::Notifier.clear_notifiers

        options.guardfile_contents
      end

      # Starts Guard and notification and show a message
      # after the Guardfile has been re-evaluated.
      #
      def _after_reevaluate_guardfile
        ::Guard::Notifier.turn_on if ::Guard::Notifier.enabled?

        if ::Guard.plugins.empty?
          ::Guard::Notifier.notify('No plugins found in Guardfile, please add at least one.', title: 'Guard re-evaluate', image: :failed)
        else
          msg = 'Guardfile has been re-evaluated.'
          ::Guard::UI.info(msg)
          ::Guard::Notifier.notify(msg, title: 'Guard re-evaluate')

          ::Guard.runner.run(:start)
        end
      end

      # Tests if the current `Guardfile` content is usable.
      #
      # @return [Boolean] if the Guardfile is usable
      #
      def _guardfile_contents_usable?
        guardfile_contents && guardfile_contents =~ /guard/m
      end

      # The path to the `Guardfile` that is located at
      # the directory, where Guard has been started from.
      #
      # @return [String] the path to the local Guardfile
      #
      def _local_guardfile_path
        File.join(Dir.pwd, 'Guardfile')
      end

      # The path to the `.Guardfile` that is located at
      # the users home directory.
      #
      # @return [String] the path to `~/.Guardfile`
      #
      def _home_guardfile_path
        File.expand_path(File.join('~', '.Guardfile'))
      end

      # The path to the user configuration `.guard.rb`
      # that is located at the users home directory.
      #
      # @return [String] the path to `~/.guard.rb`
      #
      def _user_config_path
        File.expand_path(File.join('~', '.guard.rb'))
      end

    end

  end
end
