module Guard

  # The interactor reads user input and triggers
  # specific action upon them unless its locked.
  #
  # Currently the following actions are implemented:
  #
  # - stop, quit, exit, s, q, e => Exit Guard
  # - reload, r, z => Reload Guard
  # - pause, p => Pause Guard
  # - Everything else => Run all
  #
  # It's also possible to scope `reload` and `run all` actions to only a specified group or a guard.
  #
  # @example `backend reload` will only reload backend group
  # @example `spork reload` will only reload rspec guard
  # @example `jasmine` will only run all jasmine specs
  #
  class Interactor

    STOP_ACTIONS   = %w[stop quit exit s q e]
    RELOAD_ACTIONS = %w[reload r z]
    PAUSE_ACTIONS  = %w[pause p]

    # Start the interactor in its own thread.
    #
    def start
      return if ENV["GUARD_ENV"] == 'test'

      if !@thread || !@thread.alive?
        @thread = Thread.new do
          while entry = $stdin.gets.chomp
            scopes, action = extract_scopes_and_action(entry)
            case action
            when :stop
              ::Guard.stop
            when :pause
              ::Guard.pause
            when :reload
              ::Guard::Dsl.reevaluate_guardfile if scopes.empty?
              ::Guard.reload(scopes)
            when :run_all
              ::Guard.run_all(scopes)
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
    
    # Extract guard or group scope and action from Interactor entry
    #
    # @example `spork reload` will only reload rspec
    # @example `jasmine` will only run all jasmine specs
    #
    # @param [String] Interactor entry gets from $stdin
    # @return [Array] entry group or guard scope hash and action
    #
    def extract_scopes_and_action(entry)
      scopes  = {}
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
      action ||= :run_all

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
      end
    end

  end
end
