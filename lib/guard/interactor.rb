module Guard

  autoload :ReadlineInteractor, 'guard/interactors/readline'
  autoload :SimpleInteractor,   'guard/interactors/simple'

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
  # - <enter>          => Run all
  #
  # It's also possible to scope `reload` and `run all` actions to only a specified group or a guard.
  #
  # @example Reload backend group
  #   backend reload
  #
  # @example Reload rspec guard
  #   spork reload
  #
  # @example Run all jasmine specs
  #   jasmine
  #
  # @abstract
  #
  class Interactor

    HELP_ENTRIES         = %w[help h]
    RELOAD_ENTRIES       = %w[reload r]
    STOP_ENTRIES         = %w[exit e quit q]
    PAUSE_ENTRIES        = %w[pause p]
    NOTIFICATION_ENTRIES = %w[notification n]

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
      when :readline
        ReadlineInteractor.new
      when :simple
        SimpleInteractor.new
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
      require 'readline'

      if defined?(RbReadline) || defined?(JRUBY_VERSION) || RbConfig::CONFIG['target_os'] =~ /linux/i
        ReadlineInteractor.new
      else
        SimpleInteractor.new
      end
    end

    # Start the line reader in its own thread.
    #
    def start
      return if ENV['GUARD_ENV'] == 'test'
      @thread = Thread.new { read_line } if !@thread || !@thread.alive?
    end

    # Kill interactor thread if not current
    #
    def stop
      return if ENV['GUARD_ENV'] == 'test'
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
      scopes, action = extract_scopes_and_action(line)

      case action
      when :help
        help
      when :stop
        ::Guard.stop
        exit
      when :pause
        ::Guard.pause
      when :reload
        ::Guard.reload(scopes)
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
      puts '<enter>          Run all Guards'
      puts ''
      puts 'You can scope the reload action to a specific guard or group:'
      puts ''
      puts 'rspec reload     Reload the RSpec Guard'
      puts 'backend reload   Reload the backend group'
      puts ''
      puts 'You can also run only a specific Guard or all Guards in a specific group:'
      puts ''
      puts 'jasmine          Run the jasmine Guard'
      puts 'frontend         Run all Guards in the frontend group'
      puts ''
    end

    # Extract the Guard or group scope and action from the
    # input line.
    #
    # @example `spork reload` will only reload rspec
    # @example `jasmine` will only run all jasmine specs
    #
    # @param [String] line the readline input
    # @return [Array] the group or guard scope and the action
    #
    def extract_scopes_and_action(line)
      scopes  = { }
      entries = line.split(' ')

      case entries.length
      when 1
        unless action = action_from_entry(entries[0])
          scopes = scopes_from_entry(entries[0])
        end
      when 2
        scopes = scopes_from_entry(entries[0])
        action = action_from_entry(entries[1])
      end

      action = :run_all if !action && (!scopes.empty? || entries.empty?)

      [scopes, action]
    end

    private

    # Extract guard or group scope from entry if valid
    #
    # @param [String] entry the possible scope entry
    # @return [Hash] a hash with a Guard or a group scope
    #
    def scopes_from_entry(entry)
      scopes = { }
      if guard = ::Guard.guards(entry)
        scopes[:guard] = guard
      end
      if group = ::Guard.groups(entry)
        scopes[:group] = group
      end

      scopes
    end

    # Find the action for the given input entry.
    #
    # @param [String] entry the possible action entry
    # @return [Symbol] a Guard action
    #
    def action_from_entry(entry)
      if STOP_ENTRIES.include?(entry)
        :stop
      elsif RELOAD_ENTRIES.include?(entry)
        :reload
      elsif PAUSE_ENTRIES.include?(entry)
        :pause
      elsif HELP_ENTRIES.include?(entry)
        :help
      elsif NOTIFICATION_ENTRIES.include?(entry)
        :notification
      end
    end

  end
end
