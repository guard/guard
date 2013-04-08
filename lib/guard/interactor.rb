module Guard

  # The Guard interactor is a Pry REPL with a Guard
  # specific command set.
  #
  class Interactor

    require 'pry'

    require 'guard'
    require 'guard/ui'

    require 'guard/commands/all'
    require 'guard/commands/change'
    require 'guard/commands/notification'
    require 'guard/commands/pause'
    require 'guard/commands/reload'
    require 'guard/commands/scope'
    require 'guard/commands/show'

    # The default Ruby script to configure Guard Pry if the option `:guard_rc` is not defined.
    GUARD_RC     = '~/.guardrc'

    # The default Guard Pry history file if the option `:history_file` is not defined.
    HISTORY_FILE = '~/.guard_history'

    # List of shortcuts for each interactor command
    SHORTCUTS = {
      :help         => 'h',
      :all          => 'a',
      :reload       => 'r',
      :change       => 'c',
      :show         => 's',
      :scope        => 'o',
      :notification => 'n',
      :pause        => 'p',
      :exit         => 'e',
      :quit         => 'q'
    }

    attr_accessor :thread

    class << self

      # Get the interactor options
      #
      # @return [Hash] the options
      #
      def options
        @options ||= { }
      end

      # Set the interactor options
      #
      # @param [Hash] options the interactor options
      # @option options [String] :guard_rc the Ruby script to configure Guard Pry
      # @option options [String] :history_file the file to write the Pry history to
      #
      def options=(options)
        @options = options
      end

      # Is the interactor enabled?
      #
      # @return [Boolean] true if enabled
      #
      def enabled
        @enabled.nil? ? true : @enabled
      end

      # Set the enabled status for the interactor
      #
      # @param [Boolean] status true if enabled
      #
      def enabled=(status)
        @enabled = status
      end

    end

    # Initialize the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize
      return if ENV['GUARD_ENV'] == 'test'

      Pry.config.should_load_rc       = false
      Pry.config.should_load_local_rc = false
      Pry.config.history.file         = File.expand_path(self.class.options[:history_file] || HISTORY_FILE)

      add_hooks

      replace_reset_command
      create_run_all_command
      create_command_aliases
      create_guard_commands
      create_group_commands

      configure_prompt
    end

    # Add Pry hooks:
    #
    # * Load `~/.guardrc` within each new Pry session.
    # * Load project's `.guardrc` within each new Pry session.
    # * Restore prompt after each evaluation.
    #
    def add_hooks
      Pry.config.hooks.add_hook :when_started, :load_guard_rc do
        (self.class.options[:guard_rc] || GUARD_RC).tap do |p|
          load p if File.exist?(File.expand_path(p))
        end
      end

      Pry.config.hooks.add_hook :when_started, :load_project_guard_rc do
        project_guard_rc = Dir.pwd + '/.guardrc'
        load project_guard_rc if File.exist?(project_guard_rc)
      end

      if stty_exists?
        Pry.config.hooks.add_hook :after_eval, :restore_visibility do
          system('stty echo 2>/dev/null')
        end
      end
    end

    # Replaces reset defined inside of Pry with a reset that
    # instead restarts guard.

    def replace_reset_command
      Pry.commands.command "reset", "Reset the Guard to a clean state." do
        output.puts "Guard reset."
        exec "guard"
      end
    end

    # Creates a command that triggers the `:run_all` action
    # when the command is empty (just pressing enter on the
    # beginning of a line).
    #
    def create_run_all_command
      Pry.commands.block_command /^$/, 'Hit enter to run all' do
        Pry.run_command 'all'
      end
    end

    # Creates command aliases for the commands
    # `help`, `reload`, `change`, `scope`, `notification`, `pause`, `exit` and `quit`,
    # which will be the first letter of the command.
    #
    def create_command_aliases
      SHORTCUTS.each do |command, shortcut|
        Pry.commands.alias_command shortcut, command.to_s
      end
    end

    # Create a shorthand command to run the `:run_all`
    # action on a specific Guard plugin. For example,
    # when guard-rspec is available, then a command
    # `rspec` is created that runs `all rspec`.
    #
    def create_guard_commands
      ::Guard.guards.each do |guard|
        name = guard.class.to_s.downcase.sub('guard::', '')

        Pry.commands.create_command name, "Run all #{ name }" do
          group 'Guard'

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
    def create_group_commands
      ::Guard.groups.each do |group|
        name = group.name.to_s
        next if name == 'default'

        Pry.commands.create_command name, "Run all #{ name }" do
          group 'Guard'

          def process
            Pry.run_command "all #{ match }"
          end
        end
      end
    end

    # Configure the pry prompt to see `guard` instead of
    # `pry`.
    #
    def configure_prompt
      Pry.config.prompt = [
        proc do |target_self, nest_level, pry|
          history = pry.input_array.size
          process = ::Guard.listener.paused? ? 'pause' : 'guard'
          clip    = Pry.view_clip(target_self)
          level = ":#{ nest_level }" unless nest_level.zero?
          scope = if !::Guard.scope[:plugins].empty?
                    "{#{ ::Guard.scope[:plugins].join(',') }} "
                  elsif !::Guard.scope[:groups].empty?
                    "{#{ ::Guard.scope[:groups].join(',') }} "
                  else
                    ''
                  end

          "[#{ history }] #{ scope }#{ process }(#{ clip })#{ level }> "
        end,
        proc do |target_self, nest_level, pry|
          history = pry.input_array.size
          process = ::Guard.listener.paused? ? 'pause' : 'guard'
          clip    = Pry.view_clip(target_self)
          level = ":#{ nest_level }" unless nest_level.zero?
          scope = if !::Guard.scope[:plugins].empty?
                    "{#{ ::Guard.scope[:plugins].join }} "
                  elsif !::Guard.scope[:groups].empty?
                    "{#{ ::Guard.scope[:groups].join }} "
                  else
                    ''
                  end

          "[#{ history }] #{ scope }#{ process }(#{ clip })#{ level }* "
        end
      ]
    end

    # Start the line reader in its own thread and
    # stop Guard on Ctrl-D.
    #
    def start
      return if ENV['GUARD_ENV'] == 'test'

      store_terminal_settings if stty_exists?

      if !@thread || !@thread.alive?
        ::Guard::UI.debug 'Start interactor'

        @thread = Thread.new do
          Pry.start
          ::Guard.stop
        end
      end
    end

    # Kill interactor thread if not current
    #
    def stop
      return if !@thread || ENV['GUARD_ENV'] == 'test'

      unless Thread.current == @thread
        ::Guard::UI.reset_line
        ::Guard::UI.debug 'Stop interactor'
        @thread.kill
      end

      restore_terminal_settings if stty_exists?
    end

    # Detects whether or not the stty command exists
    # on the user machine.
    #
    # @return [Boolean] the status of stty
    #
    def stty_exists?
      @stty_exists ||= system('hash', 'stty')
    end

    # Stores the terminal settings so we can resore them
    # when stopping.
    #
    def store_terminal_settings
      @stty_save = `stty -g 2>#{ DEV_NULL }`.chomp
    end

    # Restore terminal settings
    #
    def restore_terminal_settings
      system("stty #{ @stty_save } 2>#{ DEV_NULL }") if @stty_save
    end

    # Converts and validates a plain text scope
    # to a valid plugin or group scope.
    #
    # @param [Array<String>] entries the text scope
    # @return [Hash, Array<String>] the plugin or group scope, the unknown entries
    #
    def self.convert_scope(entries)
      scopes  = { :plugins => [], :groups => [] }
      unknown = []

      entries.each do |entry|
        if plugin = ::Guard.guards(entry)
          scopes[:plugins] << plugin
        elsif group = ::Guard.groups(entry)
          scopes[:groups] << group
        else
          unknown << entry
        end
      end

      [scopes, unknown]
    end
  end
end
