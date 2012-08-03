module Guard

  # The interactor triggers specific action from input
  # read by a interactor implementation.
  #
  # Currently the following actions are implemented:
  #
  # - h, help          => Show help
  # - e, exit,
  #   q. quit          => Exit Guard
  # - r, reload        => Reload Guard
  # - p, pause         => Toggle file modification listener
  # - n, notification  => Toggle notifications
  # - s, show          => Show Guard plugin configuration
  # - c, change        => Trigger a file change
  # - <enter>          => Run all
  #
  # It's also possible to scope `reload` and `run all` actions to only a specified group or a guard.
  #
  # @example Reload backend group
  #   backend reload
  #   reload backend
  #
  # @example Reload rspec guard
  #   spork reload
  #   reload spork
  #
  # @example Run all jasmine specs
  #   jasmine
  #
  # @abstract
  #
  class Interactor

    require 'guard'
    require 'guard/ui'
    require 'guard/dsl_describer'
    require 'guard/notifier'
    require 'guard/interactors/readline'
    require 'guard/interactors/coolline'
    require 'guard/interactors/simple'

    ACTIONS = {
      :help         => %w[help h],
      :reload       => %w[reload r],
      :stop         => %w[exit e quit q],
      :pause        => %w[pause p],
      :notification => %w[notification n],
      :show         => %w[show s],
      :change       => %w[change c]
    }

    # Set the interactor implementation
    #
    # @param [Symbol] interactor the name of the interactor
    #
    def self.interactor=(interactor)
      @interactor = interactor
    end

    # Get an instance of the currently configured
    # interactor implementation.
    #
    # @return [Interactor] an interactor implementation
    #
    def self.fabricate
      case @interactor
      when :coolline
        ::Guard::CoollineInteractor.new if ::Guard::CoollineInteractor.available?
      when :readline
        ::Guard::ReadlineInteractor.new if ::Guard::ReadlineInteractor.available?
      when :simple
        ::Guard::SimpleInteractor.new
      when :off
        nil
      else
        auto_detect
      end
    end

    # Tries to detect an optimal interactor for the
    # current environment.
    #
    # It returns the Readline implementation when:
    #
    # * rb-readline is installed
    # * The Ruby implementation is JRuby
    # * The current OS is not Mac OS X
    #
    # Otherwise the plain gets interactor is returned.
    #
    # @return [Interactor] an interactor implementation
    #
    def self.auto_detect
      [::Guard::CoollineInteractor, ::Guard::ReadlineInteractor, ::Guard::SimpleInteractor].detect do |interactor|
        interactor.available?(true)
      end.new
    end

    # Template method for checking if the Interactor is
    # available in the current environment?
    #
    # @param [Boolean] silent true if no error messages should be shown
    # @return [Boolean] the availability status
    #
    def self.available?(silent = false)
      true
    end

    # Start the line reader in its own thread.
    #
    def start
      return if ENV['GUARD_ENV'] == 'test'

      ::Guard::UI.debug 'Start interactor'
      @thread = Thread.new { read_line } if !@thread || !@thread.alive?
    end

    # Kill interactor thread if not current
    #
    def stop
      return if !@thread || ENV['GUARD_ENV'] == 'test'

      ::Guard::UI.debug 'Stop interactor'
      unless Thread.current == @thread
        @thread.kill
      end
    end

    # Read the user input. This method must be implemented
    # by each interactor implementation.
    #
    # @abstract
    #
    def read_line
      raise NotImplementedError
    end

    # Process the input from readline.
    #
    # @param [String] line the input line
    #
    def process_input(line)
      scopes, action, rest = extract_scopes_and_action(line)

      case action
      when :help
        help
      when :show
        ::Guard::DslDescriber.show(::Guard.options)
      when :stop
        ::Guard.stop
        exit
      when :pause
        ::Guard.pause
      when :reload
        ::Guard.reload(scopes)
      when :change
        ::Guard.within_preserved_state do
          ::Guard.runner.run_on_changes(rest, [], [])
        end
      when :run_all
        ::Guard.run_all(scopes)
      when :notification
        toggle_notification
      else
        ::Guard::UI.error "Unknown command #{ line }"
      end
    end

    # Toggle the system notifications on/off
    #
    def toggle_notification
      if ENV['GUARD_NOTIFY'] == 'true'
        ::Guard::UI.info 'Turn off notifications'
        ::Guard::Notifier.turn_off
      else
        ::Guard::Notifier.turn_on
      end
    end

    # Show the help.
    #
    def help
      puts ''
      puts '[e]xit, [q]uit   Exit Guard'
      puts '[p]ause          Toggle file modification listener'
      puts '[r]eload         Reload Guard'
      puts '[n]otification   Toggle notifications'
      puts '[s]how           Show available Guard plugins'
      puts '[c]hange <file>  Trigger a file change'
      puts '<enter>          Run all Guard plugins'
      puts ''
      puts 'You can scope the reload action to a specific guard or group:'
      puts ''
      puts 'rspec reload     Reload the RSpec Guard'
      puts 'backend reload   Reload the backend group'
      puts ''
      puts 'You can also run only a specific Guard or all Guard plugins in a specific group:'
      puts ''
      puts 'jasmine          Run the jasmine Guard'
      puts 'frontend         Run all Guard plugins in the frontend group'
      puts ''
    end

    # Extract the Guard or group scope and action from the
    # input line. There's no strict order for scopes and
    # actions.
    #
    # @example `spork reload` will only reload rspec
    # @example `jasmine` will only run all jasmine specs
    #
    # @param [String] line the readline input
    # @return [Array] the group or guard scope, the action and the rest
    #
    def extract_scopes_and_action(line)
      entries = line.split(' ')

      scopes = extract_scopes(entries)
      action = extract_action(entries)

      action = :run_all if !action && (!scopes.empty? || entries.empty?)

      [scopes, action, entries]
    end

    private

    # Extract a guard or group scope from entry if valid.
    # Any entry found will be removed from the entries.
    #
    # @param [Array<String>] entries the user entries
    # @return [Hash] a hash with a Guard or a group scope
    #
    def extract_scopes(entries)
      scopes = { }

      entries.delete_if do |entry|
        if guard = ::Guard.guards(entry)
          scopes[:guard] ||= guard
          true

        elsif group = ::Guard.groups(entry)
          scopes[:group] ||= group
          true

        else
          false
        end
      end

      scopes
    end

    # Find the action for the given input entry.
    # Any action found will be removed from the entries.
    #
    # @param [Array<String>] entries the user entries
    # @return [Symbol] a Guard action
    #
    def extract_action(entries)
      action = nil

      entries.delete_if do |entry|
        if command = ACTIONS.detect { |k, list| list.include?(entry) }
          action ||= command.first
          true
        else
          false
        end
      end

      action
    end

  end
end
