require "pry"

require "guard/commands/all"
require "guard/commands/change"
require "guard/commands/notification"
require "guard/commands/pause"
require "guard/commands/reload"
require "guard/commands/scope"
require "guard/commands/show"
require "guard/ui"

module Guard
  # The Guard interactor is a Pry REPL with a Guard
  # specific command set.
  #
  class Interactor
    # The default Ruby script to configure Guard Pry if the option `:guard_rc`
    # is not defined.
    GUARD_RC = "~/.guardrc"

    # The default Guard Pry history file if the option `:history_file` is not
    # defined.
    HISTORY_FILE = "~/.guard_history"

    # List of shortcuts for each interactor command
    SHORTCUTS = {
      help:         "h",
      all:          "a",
      reload:       "r",
      change:       "c",
      show:         "s",
      scope:        "o",
      notification: "n",
      pause:        "p",
      exit:         "e",
      quit:         "q"
    }

    attr_accessor :thread

    class << self
      # Get the interactor options
      #
      # @return [Hash] the options
      #
      def options
        @options ||= {}
      end

      # Set the interactor options
      #
      # @param [Hash] options the interactor options
      # @option options [String] :guard_rc Ruby script to configure Guard Pry
      # @option options [String] :history_file for saving Pry history
      #
      attr_writer :options

      # Is the interactor enabled?
      #
      # @return [Boolean] true if enabled
      #
      def enabled?
        @enabled || @enabled.nil?
      end

      alias_method :enabled, :enabled?

      # Set the enabled status for the interactor
      #
      # @param [Boolean] status true if enabled
      #
      attr_writer :enabled

      # Converts and validates a plain text scope
      # to a valid plugin or group scope.
      #
      # @param [Array<String>] entries the text scope
      # @return [Hash, Array<String>] the plugin or group scope, the unknown
      #   entries
      #
      def convert_scope(entries)
        scopes  = { plugins: [], groups: [] }
        unknown = []

        entries.each do |entry|
          if plugin = ::Guard.plugin(entry)
            scopes[:plugins] << plugin
          elsif group = ::Guard.group(entry)
            scopes[:groups] << group
          else
            unknown << entry
          end
        end

        [scopes, unknown]
      end
    end

    # Initializes the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize(no_interaction = false)
      @interactive = !no_interaction && self.class.enabled?
      @mutex = Mutex.new
      @thread = nil
      @stty_exists = nil

      return if ENV["GUARD_ENV"] == "test"

      _pry_setup if interactive?
    end

    def interactive?
      @interactive
    end

    # Run in foreground and wait until interrupted or closed
    def foreground
      return if ENV["GUARD_ENV"] == "test"
      ::Guard::UI.debug "Start interactor"
      _store_terminal_settings if _stty_exists?

      interactive? ?  _interactive_foreground : _non_interactive_foreground
    end

    # Remove interactor so other tasks can run in foreground
    def background
      if interactive?
        @mutex.synchronize do
          unless @thread.nil?
            @thread.kill
            @thread = nil # set to nil so we know we were killed
          end
        end
        _cleanup
        return @thread.nil? ? :stopped : :exit
      else
        Thread.main.wakeup
      end
    end

    # This is called from signal handler, so avoid actually
    # doing anything other than signaling threads
    def handle_interrupt
      return if ENV["GUARD_ENV"] == "test"

      if interactive?
        # TODO: does this actually do anything?
        if @thread
          @thread.raise Interrupt
        else
          fail Interrupt
        end
      else
        Thread.main.raise Interrupt
      end
    end

    private

    # Add Pry hooks:
    #
    # * Load `~/.guardrc` within each new Pry session.
    # * Load project's `.guardrc` within each new Pry session.
    # * Restore prompt after each evaluation.
    #
    def _add_hooks
      _add_load_guard_rc_hook
      _add_load_project_guard_rc_hook
      _add_restore_visibility_hook if _stty_exists?
    end

    # Add a `when_started` hook that loads a global .guardrc if it exists.
    #
    def _add_load_guard_rc_hook
      Pry.config.hooks.add_hook :when_started, :load_guard_rc do
        (self.class.options[:guard_rc] || GUARD_RC).tap do |p|
          load p if File.exist?(File.expand_path(p))
        end
      end
    end

    # Add a `when_started` hook that loads a project .guardrc if it exists.
    #
    def _add_load_project_guard_rc_hook
      Pry.config.hooks.add_hook :when_started, :load_project_guard_rc do
        project_guard_rc = Dir.pwd + "/.guardrc"
        load project_guard_rc if File.exist?(project_guard_rc)
      end
    end

    # Add a `after_eval` hook that restores visibility after a command is eval.
    #
    def _add_restore_visibility_hook
      Pry.config.hooks.add_hook :after_eval, :restore_visibility do
        ::Guard::Sheller.run("stty echo 2>#{ DEV_NULL }")
      end
    end

    # Replaces reset defined inside of Pry with a reset that
    # instead restarts guard.
    #
    def _replace_reset_command
      Pry.commands.command "reset", "Reset the Guard to a clean state." do
        output.puts "Guard reset."
        exec "guard"
      end
    end

    # Creates a command that triggers the `:run_all` action
    # when the command is empty (just pressing enter on the
    # beginning of a line).
    #
    def _create_run_all_command
      Pry.commands.block_command(/^$/, "Hit enter to run all") do
        Pry.run_command "all"
      end
    end

    # Creates command aliases for the commands: `help`, `reload`, `change`,
    # `scope`, `notification`, `pause`, `exit` and `quit`, which will be the
    # first letter of the command.
    #
    def _create_command_aliases
      SHORTCUTS.each do |command, shortcut|
        Pry.commands.alias_command shortcut, command.to_s
      end
    end

    # Create a shorthand command to run the `:run_all`
    # action on a specific Guard plugin. For example,
    # when guard-rspec is available, then a command
    # `rspec` is created that runs `all rspec`.
    #
    def _create_guard_commands
      ::Guard.plugins.each do |guard_plugin|
        cmd = "Run all #{ guard_plugin.title }"
        Pry.commands.create_command guard_plugin.name, cmd do
          group "Guard"

          def process
            Pry.run_command "all #{ match }"
          end
        end
      end
    end

    # Create a shorthand command to run the `:run_all`
    # action on a specific Guard group. For example,
    # when you have a group `frontend`, then a command
    # `frontend` is created that runs `all frontend`.
    #
    def _create_group_commands
      ::Guard.groups.each do |group|
        next if group.name == :default

        cmd = "Run all #{ group.title }"
        Pry.commands.create_command group.name.to_s, cmd  do
          group "Guard"

          def process
            Pry.run_command "all #{ match }"
          end
        end
      end
    end

    # Configures the pry prompt to see `guard` instead of
    # `pry`.
    #
    def _configure_prompt
      Pry.config.prompt = [_prompt(">"), _prompt("*")]
    end

    # Returns the plugins scope, or the groups scope ready for display in the
    # prompt.
    #
    def _scope_for_prompt
      scope_name = [:plugins, :groups].detect do |name|
        ! ::Guard.scope[name].empty?
      end
      scope_name ? "#{_join_scope_for_prompt(scope_name)} " : ""
    end

    # Joins the scope corresponding to the given scope name with commas.
    #
    def _join_scope_for_prompt(scope_name)
      ::Guard.scope[scope_name].map(&:title).join(",")
    end

    # Returns a proc that will return itself a string ending with the given
    # `ending_char` when called.
    #
    def _prompt(ending_char)
      proc do |target_self, nest_level, pry|
        history = pry.input_array.size
        process = ::Guard.listener.paused? ? "pause" : "guard"
        level   = ":#{ nest_level }" unless nest_level.zero?

        "[#{ history }] #{ _scope_for_prompt }#{ process }"\
          "(#{ _clip_name(target_self) })#{ level }#{ ending_char } "
      end
    end

    def _clip_name(target)
      Pry.view_clip(target)
    end

    # Detects whether or not the stty command exists
    # on the user machine.
    #
    # @return [Boolean] the status of stty
    #
    def _stty_exists?
      return @stty_exists unless @stty_exists.nil?
      @stty_exists = ::Guard::Sheller.run("hash", "stty") || false
    end

    # Stores the terminal settings so we can resore them
    # when stopping.
    #
    def _store_terminal_settings
      @stty_save = ::Guard::Sheller.stdout("stty -g 2>#{ DEV_NULL }").chomp
    end

    # Restore terminal settings
    #
    def _restore_terminal_settings
      ::Guard::Sheller.run("stty #{ @stty_save } 2>#{ DEV_NULL }") if @stty_save
    end

    # Restore terminal settings after closing
    def _cleanup
      ::Guard::UI.reset_line
      ::Guard::UI.debug "Stop interactor"
      _restore_terminal_settings if _stty_exists?
    end

    # Enter interactive mode
    def _block
      return @thread.join if interactive?

      STDERR.puts "Guards jobs done. Sleeping..."
      sleep
    end

    def _pry_setup
      Pry.config.should_load_rc = false
      Pry.config.should_load_local_rc = false
      history_file_path = self.class.options[:history_file] || HISTORY_FILE
      Pry.config.history.file = File.expand_path(history_file_path)

      _add_hooks
      _setup_commands
      _configure_prompt
    end

    def _non_interactive_foreground
      _block
      :stopped
    rescue Interrupt
      :exit
    ensure
      _cleanup
    end

    def _interactive_foreground
      @mutex.synchronize do
        unless @thread
          @thread = Thread.new { Pry.start }
          @thread.join(0.5) # give pry a chance to start
        end
      end
      _block
      _cleanup
      @thread.nil? ? :stopped : :exit
    end

    def _setup_commands
      _replace_reset_command
      _create_run_all_command
      _create_command_aliases
      _create_guard_commands
      _create_group_commands
    end
  end
end
