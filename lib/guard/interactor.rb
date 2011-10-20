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

    HELP_ACTIONS         = %w[help h]
    RELOAD_ACTIONS       = %w[reload r]
    STOP_ACTIONS         = %w[exit q]
    PAUSE_ACTIONS        = %w[pause p]
    NOTIFICATION_ACTIONS = %w[notification n]

    # Initialize the interactor.
    #
    def initialize
      Thread.abort_on_exception = true

      Readline.completion_append_character = ' '

      Readline.completion_proc = proc do |word|
        completion_list.grep(/^#{ Regexp.escape(word) }/)
      end
    end

    # Start the interactor in its own thread.
    #
    def start
      return if ENV["GUARD_ENV"] == 'test'

      if !@thread || !@thread.alive?
        @thread = Thread.new do
          while line = Readline.readline(prompt, true)
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
              puts 'Reload'
              ::Guard::Dsl.reevaluate_guardfile if scopes.empty?
              ::Guard.reload(scopes)
            when :run_all
              ::Guard.run_all(scopes)
            when :notification
              if ENV['GUARD_NOTIFY'] == 'true'
                puts 'Turn off notifications'
                ::Guard::Notifier.turn_off
              else
                ::Guard::Notifier.turn_on
              end
            else
              puts "Unknown command #{ line }"
            end
          end
        end
      end
    end

    # Kill interactor thread if not current
    #
    def stop
      unless Thread.current == @thread
        @thread.kill
      end
    end

    # Get the auto completion list.
    #
    # @return [Array<String>] the list of words
    #
    def completion_list
      commands = %w[help reload exit pause notification]
      groups   = ::Guard.groups.map { |group| group.name.to_s }
      guards   = ::Guard.guards.map { |guard| guard.class.to_s.downcase.sub('guard::', '') }

      guards + groups + commands - ['default']
    end

    # The current interactor prompt
    #
    # @return [String] the prompt to show
    #
    def prompt
      ::Guard.listener.paused? ? 'p> ' : '> '
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

    # Extract guard or group scope and action from Interactor entry
    #
    # @example `spork reload` will only reload rspec
    # @example `jasmine` will only run all jasmine specs
    #
    # @param [String] Interactor entry gets from $stdin
    # @return [Array] entry group or guard scope hash and action
    #
    def extract_scopes_and_action(entry)
      scopes  = { }
      entries = entry.split(' ')

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

    # Extract guard or group scope from entry if valid
    #
    # @param [String] Interactor entry gets from $stdin
    # @return [Hash] An hash with a guard or a group scope
    #
    def scopes_from_entry(entry)
      scopes = {}
      if guard = ::Guard.guards(entry)
        scopes[:guard] = guard
      end
      if group = ::Guard.groups(entry)
        scopes[:group] = group
      end

      scopes
    end

    # Extract action from entry if an existing action is present
    #
    # @param [String] Interactor entry gets from $stdin
    # @return [Symbol] A guard action
    #
    def action_from_entry(entry)
      if STOP_ACTIONS.include?(entry)
        :stop
      elsif RELOAD_ACTIONS.include?(entry)
        :reload
      elsif PAUSE_ACTIONS.include?(entry)
        :pause
      elsif HELP_ACTIONS.include?(entry)
        :help
      elsif NOTIFICATION_ACTIONS.include?(entry)
        :notification
      end
    end

  end
end
