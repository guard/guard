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
        :pending          => 'yellow',
        :default          => 'green',
        :timeout          => 5,
        :display_message  => false,
        :message_format   => '%s - %s',
        :line_separator   => ' - '
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

        show_message = options[:display_message] || DEFAULTS[:display_message]
        display_message(type, title, message, options) if show_message
      end

      def display_message(type, title, message, options = { })
          message_format = options[:message_format] || DEFAULTS[:message_format]
          display_time = options[:timeout] || DEFAULTS[:timeout]
          separator = options[:line_separator] || DEFAULTS[:line_separator]

          color = tmux_color type, options
          formatted_message = message.split("\n").join(separator)
          display_message = message_format % [title, formatted_message]

          system("#{ DEFAULTS[:client] } set display-time #{ display_time * 1000 }")
          system("#{ DEFAULTS[:client] } set message-bg #{ color }")
          system("#{ DEFAULTS[:client] } display-message '#{ display_message }'")
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
        when 'pending'
          options[:pending] || DEFAULTS[:pending]
        else
          options[:default] || DEFAULTS[:default]
        end
      end
    end
  end
end
