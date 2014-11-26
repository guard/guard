require "thor"

require "guard"
require "guard/version"
require "guard/dsl_describer"
require "guard/guardfile/evaluator"
require "guard/guardfile/generator"

module Guard
  # Facade for the Guard command line interface managed by
  # [Thor](https://github.com/wycats/thor).
  #
  # This is the main interface to Guard that is called by the Guard binary
  # `bin/guard`. Do not put any logic in here, create a class and delegate
  # instead.
  #
  class CLI < Thor
    default_task :start

    desc "start", "Starts Guard"

    method_option :clear,
                  type:    :boolean,
                  default: false,
                  aliases: "-c",
                  banner:  "Auto clear shell before each action"

    method_option :notify,
                  type:    :boolean,
                  default: true,
                  aliases: "-n",
                  banner:  "Notifications feature"

    method_option :debug,
                  type:    :boolean,
                  default: false,
                  aliases: "-d",
                  banner:  "Show debug information"

    method_option :group,
                  type:    :array,
                  default: [],
                  aliases: "-g",
                  banner:  "Run only the passed groups"

    method_option :plugin,
                  type:    :array,
                  default: [],
                  aliases: "-P",
                  banner:  "Run only the passed plugins"

    method_option :watchdir,
                  type:    :array,
                  aliases: "-w",
                  banner:  "Specify the directories to watch"

    method_option :guardfile,
                  type:    :string,
                  aliases: "-G",
                  banner:  "Specify a Guardfile"

    method_option :no_interactions,
                  type: :boolean,
                  default: false,
                  aliases: "-i",
                  banner: "Turn off completely any Guard terminal interactions"

    method_option :no_bundler_warning,
                  type: :boolean,
                  default: false,
                  aliases: "-B",
                  banner: "Turn off warning when Bundler is not present"

    # Listen options
    method_option :latency,
                  type:    :numeric,
                  aliases: "-l",
                  banner:  'Overwrite Listen\'s default latency'

    method_option :force_polling,
                  type:    :boolean,
                  default: false,
                  aliases: "-p",
                  banner:  "Force usage of the Listen polling listener"

    method_option :wait_for_delay,
                  type:    :numeric,
                  aliases: "-y",
                  banner:  'Overwrite Listen\'s default wait_for_delay'

    method_option :listen_on,
                  type:    :string,
                  aliases: "-o",
                  default: false,
                  banner:  "Specify a network address to Listen on for "\
                  "file change events (e.g. for use in VMs)"

    # Start Guard by initializing the defined Guard plugins and watch the file
    # system.
    #
    # This is the default task, so calling `guard` is the same as calling
    # `guard start`.
    #
    # @see Guard.start
    #
    def start
      _verify_bundler_presence unless options[:no_bundler_warning]
      ::Guard.start(options)
    end

    desc "list", "Lists Guard plugins that can be used with init"

    # List the Guard plugins that are available for use in your system and
    # marks those that are currently used in your `Guardfile`.
    #
    # @see Guard::DslDescriber.list
    #
    def list
      ::Guard::DslDescriber.new(options).list
    end

    desc "notifiers", "Lists notifiers and its options"

    # List the Notifiers for use in your system.
    #
    # @see Guard::DslDescriber.notifiers
    #
    def notifiers
      ::Guard.reset_options(options)
      ::Guard::DslDescriber.new(options).notifiers
    end

    desc "version", "Show the Guard version"
    map %w(-v --version) => :version

    # Shows the current version of Guard.
    #
    # @see Guard::VERSION
    #
    def version
      $stdout.puts "Guard version #{ ::Guard::VERSION }"
    end

    desc "init [GUARDS]", "Generates a Guardfile at the current directory"\
      " (if it is not already there) and adds all installed Guard plugins"\
      " or the given GUARDS into it"

    method_option :bare,
                  type: :boolean,
                  default: false,
                  aliases: "-b",
                  banner: "Generate a bare Guardfile without adding any"\
                  " installed plugin into it"

    # Initializes the templates of all installed Guard plugins and adds them
    # to the `Guardfile` when no Guard name is passed. When passing
    # Guard plugin names it does the same but only for those Guard plugins.
    #
    # @see Guard::Guardfile.initialize_template
    # @see Guard::Guardfile.initialize_all_templates
    #
    # @param [Array<String>] plugin_names the name of the Guard plugins to
    # initialize
    #
    def init(*plugin_names)
      _verify_bundler_presence unless options[:no_bundler_warning]

      ::Guard.reset_options(options) # Since UI.deprecated uses config

      generator = Guardfile::Generator.new(abort_on_existence: options[:bare])
      generator.create_guardfile

      # Note: this reset "hack" will be fixed after refactoring
      ::Guard.reset_plugins

      # Evaluate because it might have existed and creating was skipped
      ::Guard::Guardfile::Evaluator.new(Guard.options).evaluate_guardfile

      return if options[:bare]

      if plugin_names.empty?
        generator.initialize_all_templates
      else
        plugin_names.each do |plugin_name|
          generator.initialize_template(plugin_name)
        end
      end
    end

    desc "show", "Show all defined Guard plugins and their options"
    map %w(-T) => :show

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`
    #
    # @see Guard::DslDescriber.show
    #
    def show
      ::Guard::DslDescriber.new(options).show
    end

    private

    # Verifies if Guard is run with `bundle exec` and
    # shows a hint to do so if not.
    #
    def _verify_bundler_presence
      return unless File.exist?("Gemfile")
      return if ENV["BUNDLE_GEMFILE"] || ENV["RUBYGEMS_GEMDEPS"]

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
