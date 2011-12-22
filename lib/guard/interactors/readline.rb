module Guard

  # Interactor that used readline for getting the user input.
  # This enables history support and auto-completion, but is
  # broken on OS X without installing `rb-readline` or using JRuby.
  #
  # @see http://bugs.ruby-lang.org/issues/5539
  #
  class ReadlineInteractor < Interactor

    COMPLETION_ACTIONS   = %w[help reload exit pause notification]

    # Initialize the interactor.
    #
    def initialize
      require 'readline'

      unless defined?(RbReadline) || defined?(JRUBY_VERSION)
        ::Guard::UI.info 'Please add rb-readline for proper Readline support.'
      end

      Readline.completion_proc = proc { |word| auto_complete(word) }

      begin
        Readline.completion_append_character = ' '
      rescue NotImplementedError
        # Ignore, we just don't support it then
      end
    end

    # Read a line from stdin with Readline.
    #
    def read_line
      while line = Readline.readline(prompt, true)
        if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
          Readline::HISTORY.pop
        end

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

  end
end
