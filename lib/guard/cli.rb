require 'thor'

module Guard

  # Facade for the Guard command line interface managed by [Thor](https://github.com/wycats/thor).
  # This is the main interface to Guard that is called by the Guard binary `bin/guard`.
  # Do not put any logic in here, create a class and delegate instead.
  #
  class CLI < Thor

    require 'guard'
    require 'guard/version'
    require 'guard/dsl_describer'
    require 'guard/guardfile'

    default_task :start

    desc 'start', 'Starts Guard'

    method_option :clear,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-c',
                  :banner  => 'Auto clear shell before each action'

    method_option :notify,
                  :type    => :boolean,
                  :default => true,
                  :aliases => '-n',
                  :banner  => 'Notifications feature'

    method_option :debug,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-d',
                  :banner  => 'Show debug information'

    method_option :group,
                  :type    => :array,
                  :default => [],
                  :aliases => '-g',
                  :banner  => 'Run only the passed groups'

    method_option :plugin,
                  :type    => :array,
                  :default => [],
                  :aliases => '-P',
                  :banner  => 'Run only the passed plugins'

    method_option :watchdir,
                  :type    => :string,
                  :aliases => '-w',
                  :banner  => 'Specify the directory to watch'

    method_option :guardfile,
                  :type    => :string,
                  :aliases => '-G',
                  :banner  => 'Specify a Guardfile'

    # DEPRECATED
    method_option :no_vendor,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-I',
                  :banner  => 'DEPRECATED: Ignore vendored dependencies'

    # DEPRECATED
    method_option :watch_all_modifications,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-A',
                  :banner => 'DEPRECATED: Watch for all file modifications including moves and deletions'

    method_option :no_interactions,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-i',
                  :banner => 'Turn off completely any guard terminal interactions'

    method_option :no_bundler_warning,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-B',
                  :banner => 'Turn off warning when Bundler is not present'

    method_option :show_deprecations,
                  :type => :boolean,
                  :default => false,
                  :banner => 'Turn on deprecation warnings'

    # Listen options
    method_option :latency,
                  :type    => :numeric,
                  :aliases => '-l',
                  :banner  => 'Overwrite Listen\'s default latency'

    method_option :force_polling,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-p',
                  :banner  => 'Force usage of the Listen polling listener'

    # Start Guard by initializing the defined Guard plugins and watch the file system.
    # This is the default task, so calling `guard` is the same as calling `guard start`.
    #
    # @see Guard.start
    #
    def start
      verify_bundler_presence unless options[:no_bundler_warning]
      ::Guard.start(options)

      return if ENV['GUARD_ENV'] == 'test'

      while ::Guard.running do
        sleep 0.5
      end
    end

    desc 'list', 'Lists guards that can be used with init'

    # List the Guard plugins that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see Guard::DslDescriber.list
    #
    def list
      puts ::Guard::DslDescriber.list(options)
    end

    desc 'version', 'Show the Guard version'
    map %w(-v --version) => :version

    # Shows the current version of Guard.
    #
    # @see Guard::VERSION
    #
    def version
      puts "Guard version #{ ::Guard::VERSION }"
    end

    desc 'init [GUARDS]', 'Generates a Guardfile at the current directory (if it is not already there) and adds all installed guards or the given GUARDS into it'

    method_option :bare,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-b',
                  :banner => 'Generate a bare Guardfile without adding any installed guard into it'

    # Initializes the templates of all installed Guard plugins and adds them
    # to the `Guardfile` when no Guard name is passed. When passing
    # Guard plugin names it does the same but only for those Guard plugins.
    #
    # @see Guard::Guard.initialize_template
    # @see Guard::Guard.initialize_all_templates
    #
    # @param [Array<String>] guard_names the name of the Guard plugins to initialize
    #
    def init(*guard_names)
      verify_bundler_presence

      ::Guard::Guardfile.create_guardfile(:abort_on_existence => options[:bare])

      return if options[:bare]

      if guard_names.empty?
        ::Guard::Guardfile::initialize_all_templates
      else
        guard_names.each do |guard_name|
          ::Guard::Guardfile.initialize_template(guard_name)
        end
      end
    end

    desc 'show', 'Show all defined Guard plugins and their options'
    map %w(-T) => :show

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`
    #
    # @see Guard::DslDescriber.show
    #
    def show
      puts ::Guard::DslDescriber.show(options)
    end

    private

    # Verifies if Guard is run with `bundle exec` and
    # shows a hint to do so if not.
    #
    def verify_bundler_presence
      if File.exists?('Gemfile') && !ENV['BUNDLE_GEMFILE']
        ::Guard::UI.info <<EOF

Guard here! It looks like your project has a Gemfile, yet you are running
`guard` outside of Bundler. If this is your intent, feel free to ignore this
message. Otherwise, consider using `bundle exec guard` to ensure your
dependencies are loaded correctly.
(You can run `guard` with --no-bundler-warning to get rid of this message.)
EOF
      end
    end

  end
end
