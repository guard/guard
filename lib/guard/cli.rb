require 'thor'
require 'guard/version'

module Guard

  # Guard command line interface managed by [Thor](https://github.com/wycats/thor).
  # This is the main interface to Guard that is called by the Guard binary `bin/guard`.
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
    # @example Guard list output
    #
    #   Available guards:
    #     bundler *
    #     livereload
    #     ronn
    #     rspec *
    #     spork
    #
    #   See also https://github.com/guard/guard/wiki/List-of-available-Guards
    #   * denotes ones already in your Guardfile
    #
    # @see Guard::DslDescriber
    #
    def list
      Guard::DslDescriber.evaluate_guardfile(options)

      installed = Guard::DslDescriber.guardfile_structure.inject([]) do |installed, group|
        group[:guards].each { |guard| installed << guard[:name] } if group[:guards]
        installed
      end

      Guard::UI.info 'Available guards:'

      Guard::guard_gem_names.sort.uniq.each do |name|
        Guard::UI.info "   #{ name } #{ installed.include?(name) ? '*' : '' }"
      end

      Guard::UI.info ' '
      Guard::UI.info 'See also https://github.com/guard/guard/wiki/List-of-available-Guards'
      Guard::UI.info '* denotes ones already in your Guardfile'
    end

    desc 'version', 'Show the Guard version'
    map %w(-v --version) => :version

    # Shows the current version of Guard.
    #
    # @see Guard::VERSION
    #
    def version
      Guard::UI.info "Guard version #{ Guard::VERSION }"
    end

    desc 'init [GUARD]', 'Generates a Guardfile at the current working directory, or insert the given GUARD to an existing Guardfile'

    # Appends the Guard template to the `Guardfile`, or creates an initial
    # `Guardfile` when no Guard name is passed.
    #
    # @param [String] guard_name the name of the Guard to initialize
    #
    def init(guard_name = nil)
      if guard_name
        guard_class = ::Guard.get_guard_class(guard_name)
        guard_class.init(guard_name)

      else
        if File.exist?('Guardfile')
          puts 'Writing new Guardfile to #{Dir.pwd}/Guardfile'
          FileUtils.cp(File.expand_path('../templates/Guardfile', __FILE__), 'Guardfile')
        else
          Guard::UI.error "Guardfile already exists at #{ Dir.pwd }/Guardfile"
          exit 1
        end
      end
    end

    desc 'show', 'Show all defined Guards and their options'
    map %w(-T) => :show

    # Shows all Guards and their options that are defined in
    # the `Guardfile`.
    #
    # @example guard show output
    #
    #   (global):
    #     bundler
    #     coffeescript: input => "app/assets/javascripts", noop => true
    #     jasmine
    #     rspec: cli => "--fail-fast --format Fuubar
    #
    # @see Guard::DslDescriber
    #
    def show
      Guard::DslDescriber.evaluate_guardfile(options)

      Guard::DslDescriber.guardfile_structure.each do |group|
        unless group[:guards].empty?
          if group[:group]
            Guard::UI.info "Group #{ group[:group] }:"
          else
            Guard::UI.info '(global):'
          end

          group[:guards].each do |guard|
            line = "  #{ guard[:name] }"

            unless guard[:options].empty?
              line += ": #{ guard[:options].collect { |k, v| "#{ k } => #{ v.inspect }" }.join(', ') }"
            end

            Guard::UI.info line
          end
        end
      end

      Guard::UI.info ''
    end

  end
end
