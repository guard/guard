require 'guard'
require 'guard/ui'
require 'guard/interactor'
require 'guard/interactors/helpers/terminal'
require 'guard/interactors/helpers/completion'

module Guard

  # Interactor that used readline for getting the user input.
  # This enables history support and auto-completion, but is
  # broken on OS X without installing `rb-readline` or using JRuby.
  #
  # @see http://bugs.ruby-lang.org/issues/5539
  #
  class ReadlineInteractor < ::Guard::Interactor
    include ::Guard::CompletionHelper
    include ::Guard::TerminalHelper

    # Test if the Interactor is
    # available in the current environment?
    #
    # @param [Boolean] silent true if no error messages should be shown
    # @return [Boolean] the availability status
    #
    def self.available?(silent = false)
      require 'readline'

      if defined?(RbReadline) || defined?(JRUBY_VERSION) || RbConfig::CONFIG['target_os'] =~ /linux/i
        true
      else
        ::Guard::UI.error 'The :readline interactor runs only fine on JRuby, Linux or with the gem \'rb-readline\' installed.' unless silent
        false
      end

    rescue LoadError => e
      ::Guard::UI.error "Please install Ruby Readline support or add \"gem 'rb-readline'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
      false      
    end

    # Initialize the interactor.
    #
    def initialize
      require 'readline'

      Readline.completion_proc = proc { |word| auto_complete(word) }

      begin
        Readline.completion_append_character = ' '
      rescue NotImplementedError
        # Ignore, we just don't support it then
      end
    end

    # Stop the interactor.
    #
    def stop
      # Erase the current line for Ruby Readline
      if Readline.respond_to?(:refresh_line) && !defined?(::JRUBY_VERSION)
        Readline.refresh_line
      end

      # Erase the current line for Rb-Readline
      if defined?(RbReadline) && RbReadline.rl_outstream
        RbReadline._rl_erase_entire_line
      end

      super
    end

    # Read a line from stdin with Readline.
    #
    def read_line
      require 'readline'

      while line = Readline.readline(prompt, true)
        line.gsub!(/^\W*/, '')
        if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
          Readline::HISTORY.pop
        end

        process_input(line)
      end
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
