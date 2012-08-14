module Guard

  # Module for resetting terminal options for an interactor.
  #
  module TerminalHelper

    # Start the interactor.
    #
    def start
      store_terminal_settings if stty_exists?
      super
    end

    # Stop the interactor.
    #
    def stop
      super
      restore_terminal_settings if stty_exists?
    end

    private

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

  end
end
