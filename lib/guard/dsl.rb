module Guard

  # The DSL class provides the methods that are used in each `Guardfile` to describe
  # the behaviour of Guard.
  #
  # The main keywords of the DSL are `guard` and `watch`. These are necessary to define
  # the used Guards and the file changes they are watching.
  #
  # You can optionally group the Guards with the `group` keyword and ignore certain paths
  # with the `ignore_paths` keyword.
  #
  # A more advanced DSL use is the `callback` keyword that allows you to execute arbitrary
  # code before or after any of the `start`, `stop`, `reload`, `run_all` and `run_on_change`
  # Guards' method. You can even insert more hooks inside these methods.
  # Please [checkout the Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for more details.
  #
  # The DSL will also evaluate normal Ruby code.
  #
  # There are two possible locations for the `Guardfile`:
  # - The `Guardfile` in the current directory where Guard has been started
  # - The `.Guardfile` in your home directory.
  #
  # In addition, if a user configuration `.guard.rb` in your home directory is found, it will
  # be appended to the current project `Guardfile`.
  #
  # @example A sample of a complex Guardfile
  #
  #   group 'frontend' do
  #     guard 'passenger', :ping => true do
  #       watch('config/application.rb')
  #       watch('config/environment.rb')
  #       watch(%r{^config/environments/.+\.rb})
  #       watch(%r{^config/initializers/.+\.rb})
  #     end
  #
  #     guard 'livereload', :apply_js_live => false do
  #       watch(%r{^app/.+\.(erb|haml)})
  #       watch(%r{^app/helpers/.+\.rb})
  #       watch(%r{^public/javascripts/.+\.js})
  #       watch(%r{^public/stylesheets/.+\.css})
  #       watch(%r{^public/.+\.html})
  #       watch(%r{^config/locales/.+\.yml})
  #     end
  #   end
  #
  #   group 'backend' do
  #     # Reload the bundle when the Gemfile is modified
  #     guard 'bundler' do
  #       watch('Gemfile')
  #     end
  #
  #     # for big project you can fine tune the "timeout" before Spork's launch is considered failed
  #     guard 'spork', :wait => 40 do
  #       watch('Gemfile')
  #       watch('config/application.rb')
  #       watch('config/environment.rb')
  #       watch(%r{^config/environments/.+\.rb})
  #       watch(%r{^config/initializers/.+\.rb})
  #       watch('spec/spec_helper.rb')
  #     end
  #
  #     # use RSpec 2, from the system's gem and with some direct RSpec CLI options
  #     guard 'rspec', :version => 2, :cli => "--color --drb -f doc", :bundler => false do
  #       watch('spec/spec_helper.rb')                                  { "spec" }
  #       watch('app/controllers/application_controller.rb')            { "spec/controllers" }
  #       watch('config/routes.rb')                                     { "spec/routing" }
  #       watch(%r{^spec/support/(controllers|acceptance)_helpers\.rb}) { |m| "spec/#{m[1]}" }
  #       watch(%r{^spec/.+_spec\.rb})
  #
  #       watch(%r{^app/controllers/(.+)_(controller)\.rb}) { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  #
  #       watch(%r{^app/(.+)\.rb}) { |m| "spec/#{m[1]}_spec.rb" }
  #       watch(%r{^lib/(.+)\.rb}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  #     end
  #   end
  #
  class Dsl
    class << self

      @@options = nil

      # Evaluate the DSL methods in the `Guardfile`.
      #
      # @option options [Array<Symbol,String>] groups the groups to evaluate
      # @option options [String] guardfile the path to a valid Guardfile
      # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
      # @raise [ArgumentError] when options are not a Hash
      #
      def evaluate_guardfile(options = {})
        raise ArgumentError.new('No option hash passed to evaluate_guardfile!') unless options.is_a?(Hash)

        @@options = options.dup

        fetch_guardfile_contents
        instance_eval_guardfile(guardfile_contents_with_user_config)

        UI.error 'No guards found in Guardfile, please add at least one.' if !::Guard.guards.nil? && ::Guard.guards.empty?
      end

      # Re-evaluate the `Guardfile` to update the current Guard configuration.
      #
      def reevaluate_guardfile
        ::Guard.guards.clear
        ::Guard.reset_groups
        @@options.delete(:guardfile_contents)
        Dsl.evaluate_guardfile(@@options)
        msg = 'Guardfile has been re-evaluated.'
        UI.info(msg)
        Notifier.notify(msg)
      end

      # Evaluate the content of the `Guardfile`.
      #
      # @param [String] contents the content to evaluate.
      #
      def instance_eval_guardfile(contents)
        new.instance_eval(contents, @@options[:guardfile_path], 1)
      rescue
        UI.error "Invalid Guardfile, original error is:\n#{ $! }"
        exit 1
      end

      # Test if the current `Guardfile` contains a specific Guard.
      #
      # @param [String] guard_name the name of the Guard
      # @return [Boolean] whether the Guard has been declared
      #
      def guardfile_include?(guard_name)
        guardfile_contents.match(/^guard\s*\(?\s*['":]#{ guard_name }['"]?/)
      end

      # Read the current `Guardfile` content.
      #
      # @param [String] the path to the Guardfile
      #
      def read_guardfile(guardfile_path)
        @@options[:guardfile_path]     = guardfile_path
        @@options[:guardfile_contents] = File.read(guardfile_path)
      rescue
        UI.error("Error reading file #{ guardfile_path }")
        exit 1
      end

      # Get the content to evaluate and stores it into
      # the options as `:guardfile_contents`.
      #
      def fetch_guardfile_contents
        if @@options[:guardfile_contents]
          UI.info 'Using inline Guardfile.'
          @@options[:guardfile_path] = 'Inline Guardfile'

        elsif @@options[:guardfile]
          if File.exist?(@@options[:guardfile])
            read_guardfile(@@options[:guardfile])
            UI.info "Using Guardfile at #{ @@options[:guardfile] }."
          else
            UI.error "No Guardfile exists at #{ @@options[:guardfile] }."
            exit 1
          end

        else
          if File.exist?(guardfile_default_path)
            read_guardfile(guardfile_default_path)
          else
            UI.error 'No Guardfile found, please create one with `guard init`.'
            exit 1
          end
        end

        unless guardfile_contents_usable?
          UI.error "The command file(#{ @@options[:guardfile] }) seems to be empty."
          exit 1
        end
      end

      # Get the content of the `Guardfile`.
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents
        @@options ? @@options[:guardfile_contents] : ''
      end

      # Get the content of the `Guardfile` and the global
      # user configuration file.
      #
      # @see #user_config_path
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents_with_user_config
        config = File.read(user_config_path) if File.exist?(user_config_path)
        [guardfile_contents, config].join("\n")
      end

      # Get the file path to the project `Guardfile`.
      #
      # @return [String] the path to the Guardfile
      #
      def guardfile_path
        @@options ? @@options[:guardfile_path] : ''
      end

      # Tests if the current `Guardfile` content is usable.
      #
      # @return [Boolean] if the Guardfile is usable
      #
      def guardfile_contents_usable?
        guardfile_contents && guardfile_contents.size >= 'guard :a'.size # Smallest Guard definition
      end

      # Gets the default path of the `Guardfile`. This returns the `Guardfile`
      # from the current directory when existing, or the global `.Guardfile`
      # at the home directory.
      #
      # @return [String] the path to the Guardfile
      #
      def guardfile_default_path
        File.exist?(local_guardfile_path) ? local_guardfile_path : home_guardfile_path
      end

      private

      # The path to the `Guardfile` that is located at
      # the directory, where Guard has been started from.
      #
      # @param [String] the path to the local Guardfile
      #
      def local_guardfile_path
        File.join(Dir.pwd, 'Guardfile')
      end

      # The path to the `.Guardfile` that is located at
      # the users home directory.
      #
      # @param [String] the path to ~/.Guardfile
      #
      def home_guardfile_path
        File.expand_path(File.join('~', '.Guardfile'))
      end

      # The path to the user configuration `.guard.rb`
      # that is located at the users home directory.
      #
      # @param [String] the path to ~/.guard.rb
      #
      def user_config_path
        File.expand_path(File.join('~', '.guard.rb'))
      end

    end

    # Declares a group of guards to be run with `guard start --group group_name`.
    #
    # @example Declare two groups of Guards
    #
    #   group 'backend' do
    #     guard 'spork'
    #     guard 'rspec'
    #   end
    #
    #   group 'frontend' do
    #     guard 'passenger'
    #     guard 'livereload'
    #   end
    #
    # @param [Symbol, String] name the group's name called from the CLI
    # @param [Hash] options the options accepted by the group
    # @yield a block where you can declare several guards
    #
    # @see Guard.add_group
    # @see Dsl#guard
    # @see Guard::DslDescriber
    #
    def group(name, options = {})
      @groups = @@options[:group] || []
      name    = name.to_sym

      if block_given? && (@groups.empty? || @groups.map(&:to_sym).include?(name))
        ::Guard.add_group(name.to_s.downcase, options)
        @current_group = name

        yield if block_given?

        @current_group = nil
      end
    end

    # Declare a guard to be used when running `guard start`.
    #
    # The name parameter is usually the name of the gem without
    # the 'guard-' prefix.
    #
    # The available options are different for each Guard implementation.
    #
    # @example Declare a Guard
    #
    #   guard 'rspec' do
    #   end
    #
    # @param [String] name the Guard name
    # @param [Hash] options the options accepted by the Guard
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Guard.add_guard
    # @see Dsl#group
    # @see Dsl#watch
    # @see Guard::DslDescriber
    #
    def guard(name, options = {})
      @watchers  = []
      @callbacks = []

      yield if block_given?

      options.update(:group => (@current_group || :default))
      ::Guard.add_guard(name.to_s.downcase, @watchers, @callbacks, options)
    end

    # Define a pattern to be watched in order to run actions on file modification.
    #
    # @example Declare watchers for a Guard
    #
    #   guard 'rspec' do
    #     watch('spec/spec_helper.rb')
    #     watch(%r{^.+_spec.rb})
    #     watch(%r{^app/controllers/(.+).rb}) { |m| 'spec/acceptance/#{m[1]}s_spec.rb' }
    #   end
    #
    # @param [String, Regexp] pattern the pattern to be watched by the guard
    # @yield a block to be run when the pattern is matched
    # @yieldparam [MatchData] m matches of the pattern
    # @yieldreturn a directory, a filename, an array of directories / filenames, or nothing (can be an arbitrary command)
    #
    # @see Guard::Watcher
    # @see Dsl#guard
    #
    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end

    # Define a callback to execute arbitrary code before or after any of
    # the `start`, `stop`, `reload`, `run_all` and `run_on_change` guards' method.
    #
    # @param [Array] args the callback arguments
    # @yield a block with listeners
    #
    # @see Guard::Hook
    #
    def callback(*args, &listener)
      listener, events = args.size > 1 ? args : [listener, args[0]]
      @callbacks << { :events => events, :listener => listener }
    end

    # Ignore certain paths globally.
    #
    # @example Ignore some paths
    #   ignore_paths ".git", ".svn"
    #
    # @param [Array] paths the list of paths to ignore
    #
    # @see Guard::Listener
    #
    def ignore_paths(*paths)
      UI.info "Ignoring paths: #{ paths.join(', ') }"
      ::Guard.listener.ignore_paths.push(*paths)
    end

  end
end
