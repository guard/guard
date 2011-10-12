require 'thor'
require 'guard/version'

module Guard

  # Facade for the Guard command line interface managed by [Thor](https://github.com/wycats/thor).
  # This is the main interface to Guard that is called by the Guard binary `bin/guard`.
  # Do not put any logic in here, create a class and delegate instead.
  #
  class CLI < Thor

    default_task :start

    desc 'start', 'Starts Guard'

    method_option :clear,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-c',
                  :banner  => 'Auto clear shell before each change/run_all/reload'

    method_option :notify,
                  :type    => :boolean,
                  :default => true,
                  :aliases => '-n',
                  :banner  => 'Notifications feature (growl/libnotify)'

    method_option :debug,
                  :type    => :boolean,
                  :default => false,
                  :aliases => '-d',
                  :banner  => 'Print debug messages'

    method_option :group,
                  :type    => :array,
                  :default => [],
                  :aliases => '-g',
                  :banner  => 'Run only the passed groups'

    method_option :watchdir,
                  :type    => :string,
                  :aliases => '-w',
                  :banner  => 'Specify the directory to watch'

    method_option :guardfile,
                  :type    => :string,
                  :aliases => '-G',
                  :banner  => 'Specify a Guardfile'

    method_option :watch_all_modifications,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-A',
                  :banner => 'Watch for all file modifications including moves and deletions'

    method_option :no_interactions,
                  :type => :boolean,
                  :default => false,
                  :aliases => '-i',
                  :banner => 'Turn off completely any guard terminal interactions'

    # Start Guard by initialize the defined Guards and watch the file system.
    # This is the default task, so calling `guard` is the same as calling `guard start`.
    #
    # @see Guard.start
    #
    def start
      ::Guard.start(options)
    end

    desc 'list', 'Lists guards that can be used with init'

    # List the Guards that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see Guard::DslDescriber.list
    #
    def list
      ::Guard::DslDescriber.list(options)
    end

    desc 'version', 'Show the Guard version'
    map %w(-v --version) => :version

    # Shows the current version of Guard.
    #
    # @see Guard::VERSION
    #
    def version
      ::Guard::UI.info "Guard version #{ Guard::VERSION }"
    end

    desc 'init [GUARD]', 'Generates a Guardfile at the current working directory, or insert the given GUARD to an existing Guardfile'

    # Appends the Guard template to the `Guardfile`, or creates an initial
    # `Guardfile` when no Guard name is passed.
    #
    # @see Guard.initialize_template
    #
    # @param [String] guard_name the name of the Guard to initialize
    #
    def init(guard_name = nil)
      ::Guard.initialize_template(guard_name)
    end

    desc 'show', 'Show all defined Guards and their options'
    map %w(-T) => :show

    # Shows all Guards and their options that are defined in
    # the `Guardfile`.
    #
    # @see Guard::DslDescriber.show
    #
    def show
      ::Guard::DslDescriber.show(options)
    end

  end
end
