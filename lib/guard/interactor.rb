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

    def initialize
      return if ENV['GUARD_ENV'] == 'test'

      Pry.config.history.file = HISTORY_FILE

      Pry.config.hooks.add_hook :when_started, :load_guard_rc do
        load GUARD_RC if File.exist? File.expand_path GUARD_RC
      end

      %w(help reload change show notification pause exit).each do |command|
        Pry.commands.alias_command command[0].chr, command
      end

      Pry.commands.block_command /^$/, 'Hit enter to run all tests' do
        Pry.run_command 'all'
      end

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
