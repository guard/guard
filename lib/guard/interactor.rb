require 'readline'

module Guard

  # The interactor reads user input and triggers
  # specific action upon them unless its locked.
  #
  # It used the readline library for history and
  # completion support.
  #
  # Currently the following actions are implemented:
  #
  # - h, help         => Show help
  # - e, exit         => Exit Guard
  # - r, reload       => Reload Guard
  # - p, pause        => Toggle file modification listener
  # - n, notification => Toggle notifications
  # - <enter>         => Run all
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
  class Interactor

    HELP_ENTRIES         = %w[help h]
    RELOAD_ENTRIES       = %w[reload r]
    STOP_ENTRIES         = %w[exit e]
    PAUSE_ENTRIES        = %w[pause p]
    NOTIFICATION_ENTRIES = %w[notification n]

    COMPLETION_ACTIONS   = %w[help reload exit pause notification]

    # Initialize the interactor.
    #
    def initialize
      Readline.completion_append_character = ' '
      Readline.completion_proc             = proc { |word| auto_complete(word) }
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
      unless Thread.current == @thread
        @thread.kill
      end
    end

    # Read a line from stdin with Readline.
    #
    def read_line
      while line = Readline.readline(prompt, true)
        process_input(line)
      end
    end

    # Auto complete the given word.
    #
    # @param [String] word the partial word
    # @return [Array<String>] the matching words
    #
    def auto_complete(word)
      completion_list.grep(/^#{ Regexp.escape(word) }/)
    end

    # Get the auto completion list.
    #
    # @return [Array<String>] the list of words
    #
    def completion_list
      groups = ::Guard.groups.map { |group| group.name.to_s }
      guards = ::Guard.guards.map { |guard| guard.class.to_s.downcase.sub('guard::', '') }

      COMPLETION_ACTIONS + groups + guards - ['default']
    end

    # The current interactor prompt
    #
    # @return [String] the prompt to show
    #
    def prompt
      ::Guard.listener.paused? ? 'p> ' : '> '
    end

    # Process the input from readline.
    #
    # @param [String] line the input line
    #
    def process_input(line)
      if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
        Readline::HISTORY.pop
      end

      scopes, action = extract_scopes_and_action(line)

      case action
      when :help
        help
      when :stop
        ::Guard.stop
      when :pause
        ::Guard.pause
      when :reload
        reload(scopes)
      when :run_all
        ::Guard.run_all(scopes)
      when :notification
        toggle_notification
      else
        ::Guard::UI.error "Unknown command #{ line }"
      end
    end

    # Execute the reload action.
    #
    # @param [Hash] scopes the reload scopes
    #
    def reload(scopes)
      puts 'Reload'
      ::Guard::Dsl.reevaluate_guardfile if scopes.empty?
      ::Guard.reload(scopes)
    end

    # Toggle the system notifications on/off
    #
    def toggle_notification
      if ENV['GUARD_NOTIFY'] == 'true'
        puts 'Turn off notifications'
        ::Guard::Notifier.turn_off
      else
        ::Guard::Notifier.turn_on
      end
    end

    # Show the help.
    #
    def help
      puts ''
      puts 'e, exit          Exit Guard'
      puts 'p, pause         Toggle file modification listener'
      puts 'r, reload        Reload Guard'
      puts 'n, notification  Toggle notifications'
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
