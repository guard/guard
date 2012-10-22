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
    require 'guard/commands/show'

    GUARD_RC = '~/.guardrc'
    HISTORY_FILE = '~/.guard_history'

    # Initialize the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize
      return if ENV['GUARD_ENV'] == 'test'

      Pry.config.history.file = HISTORY_FILE

      load_guard_rc

      create_run_all_command
      create_command_aliases
      create_guard_commands
      create_group_commands

      configure_prompt
    end

    # Loads the `~/.guardrc` file when pry has started.
    #
    def load_guard_rc
      Pry.config.hooks.add_hook :when_started, :load_guard_rc do
        load GUARD_RC if File.exist? File.expand_path GUARD_RC
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
    # `help`, `reload`, `change`, `show`, `notification`, `pause`, `exit` and `quit`,
    # which will be the first letter of the command.
    #
    def create_command_aliases
      %w(help reload change show notification pause exit quit).each do |command|
        Pry.commands.alias_command command[0].chr, command
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
          "[#{ pry.input_array.size }] #{ ::Guard.listener.paused? ? 'pause' : 'guard' }(#{ Pry.view_clip(target_self) })#{":#{ nest_level }" unless nest_level.zero? }> "
        end,
        proc do |target_self, nest_level, pry|
          "[#{ pry.input_array.size }] #{ ::Guard.listener.paused? ? 'pause' : 'guard' }(#{ Pry.view_clip(target_self) })#{":#{ nest_level }" unless nest_level.zero? }* "
        end
      ]
    end

    # Start the line reader in its own thread.
    #
    def start
      return if ENV['GUARD_ENV'] == 'test'

      store_terminal_settings if stty_exists?

      if !@thread || !@thread.alive?
        ::Guard::UI.debug 'Start interactor'

        @thread = Thread.new do
          Pry.start
          ::Guard.stop
          exit
        end
      end
    end

    # Kill interactor thread if not current
    #
    def stop
      return if !@thread || ENV['GUARD_ENV'] == 'test'

      unless Thread.current == @thread
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
      @stty_save = `stty -g 2>/dev/null`.chomp
    end

    # Restore terminal settings
    #
    def restore_terminal_settings
      system("stty #{ @stty_save } 2>/dev/null") if @stty_save
    end

    # Converts and validates a plain text scope
    # to a valid plugin or group scope.
    #
    # @param [Array<String>] entries the text scope
    # @return [Hash, Array<String>] the plugin or group scope, the unknown entries
    #
    def self.convert_scope(entries)
      scopes  = { }
      unknown = []

      entries.each do |entry|
        if guard = ::Guard.guards(entry)
          scopes[:guard] ||= guard
        elsif group = ::Guard.groups(entry)
          scopes[:group] ||= group
        else
          unknown << entry
        end
      end

      [scopes, unknown]
    end
  end
end
