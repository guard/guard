module Guard
  module Notifier

    # Default options for Tmux

    # Changes the color of the Tmux status bar
    #
    # @example Add the `:tmux` notifier to your `Guardfile`
    #   notification :tmux
    #
    module Tmux
      extend self

      DEFAULTS = {
        :client           => 'tmux',
        :tmux_environment => 'TMUX',
        :success          => 'green',
        :failed           => 'red',
        :default          => 'green'
      }

      # Test if currently running in a Tmux session
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        if ENV[DEFAULTS[:tmux_environment]].nil?
          ::Guard::UI.error 'The :tmux notifier runs only on when Guard is executed inside of a tmux session.' unless silent
          false
        else
          true
        end
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [Boolean] sticky make the notification sticky
      # @option options [String, Integer] priority specify an int or named key (default is 0)
      #
      def notify(type, title, message, image, options = { })
        color = tmux_color type, options
        system("#{ DEFAULTS[:client] } set -g status-left-bg #{ color }")
      end

      # Get the Tmux color for the notification type.
      # You can configure your own color by overwriting the defaults.
      #
      # @param [String] type the notification type
      # @return [String] the name of the emacs color
      #
      def tmux_color(type, options = { })
        case type
        when 'success'
          options[:success] || DEFAULTS[:success]
        when 'failed'
          options[:failed]  || DEFAULTS[:failed]
        else
          options[:default] || DEFAULTS[:default]
        end
      end
    end
  end
end
