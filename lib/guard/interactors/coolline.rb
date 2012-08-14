require 'guard'
require 'guard/ui'
require 'guard/interactor'
require 'guard/interactors/helpers/terminal'
require 'guard/interactors/helpers/completion'

module Guard

  # Interactor that uses coolline for getting the user input.
  # This enables history support and auto-completion,
  #
  class CoollineInteractor < ::Guard::Interactor
    include ::Guard::CompletionHelper
    include ::Guard::TerminalHelper

    # Test if the Interactor is
    # available in the current environment?
    #
    # @param [Boolean] silent true if no error messages should be shown
    # @return [Boolean] the availability status
    #
    def self.available?(silent = false)
      if RbConfig::CONFIG['RUBY_PROGRAM_VERSION'] == '1.9.3'
        require 'coolline'
        true
      else
        ::Guard::UI.error 'The :coolline interactor runs only on Ruby 1.9.3.' unless silent
        false
      end

    rescue LoadError => e
      ::Guard::UI.error "Please add \"gem 'coolline'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
      false
    end

    # Read a line from stdin with Readline.
    #
    def read_line
      coolline = Coolline.new do |cool|
        cool.transform_proc = proc do
          cool.line
        end

        cool.completion_proc = proc do
          word = cool.completed_word
          auto_complete(word)
        end
      end

      while line = coolline.readline(prompt)
        process_input(line)
      end
    end

    # The current interactor prompt
    #
    # @return [String] the prompt to show
    #
    def prompt
      ::Guard.listener.paused? ? 'p> ' : '>> '
    end

  end
end
