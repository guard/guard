module Guard
  module Notifier

    # Changes the color of the Tmux status bar and optionally
    # shows messages in the status bar.
    #
    # @example Add the `:tmux` notifier to your `Guardfile`
    #   notification :tmux
    #
    # @example Enable text messages
    #   notification :tmux, :display_message => true
    #
    # @example Customize the tmux status colored for notifications
    #   notification :tmux, :color_location => 'status-right-bg'
    #
    module Tmux
      extend self

      # Default options for Tmux
      DEFAULTS = {
        :client                 => 'tmux',
        :tmux_environment       => 'TMUX',
        :success                => 'green',
        :failed                 => 'red',
        :pending                => 'yellow',
        :default                => 'green',
        :timeout                => 5,
        :display_message        => false,
        :default_message_format => '%s - %s',
        :default_message_color  => 'white',
        :line_separator         => ' - ',
        :color_location         => 'status-left-bg'
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

      # Show a system notification. By default, the Tmux notifier only makes use of a color based
      # notification, changing the background color of the `color_location` to the color defined
      # in either the `success`, `failed`, `pending` or `default`, depending on the notification type.
      # If you also want display a text message, you have to enable it explicit by setting `display_message`
      # to `true`.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [String] color_location the location where to draw the color notification
      # @option options [Boolean] display_message whether to display a message or not
      #
      def notify(type, title, message, image, options = { })
        color = tmux_color(type, options)
        color_location = options[:color_location] || DEFAULTS[:color_location]

        system("#{ DEFAULTS[:client] } set #{ color_location } #{ color }")

        show_message = options[:display_message] || DEFAULTS[:display_message]
        display_message(type, title, message, options) if show_message
      end

      # Display a message in the status bar of tmux.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [Hash] options additional notification library options
      # @option options [Integer] timeout the amount of seconds to show the message in the status bar
      # @option options [String] success_message_format a string to use as formatter for the success message.
      # @option options [String] failed_message_format a string to use as formatter for the failed message.
      # @option options [String] pending_message_format a string to use as formatter for the pending message.
      # @option options [String] default_message_format a string to use as formatter when no format per type is defined.
      # @option options [String] success_message_color the success notification foreground color name.
      # @option options [String] failed_message_color the failed notification foreground color name.
      # @option options [String] pending_message_color the pending notification foreground color name.
      # @option options [String] default_message_color a notification foreground color to use when no color per type is defined.
      # @option options [String] line_separator a string to use instead of a line-break.
      #
      def display_message(type, title, message, options = { })
          message_format = options["#{ type }_message_format".to_sym] || options[:default_message_format] || DEFAULTS[:default_message_format]
          message_color = options["#{ type }_message_color".to_sym] || options[:default_message_color] || DEFAULTS[:default_message_color]
          display_time = options[:timeout] || DEFAULTS[:timeout]
          separator = options[:line_separator] || DEFAULTS[:line_separator]

          color = tmux_color type, options
          formatted_message = message.split("\n").join(separator)
          display_message = message_format % [title, formatted_message]

          system("#{ DEFAULTS[:client] } set display-time #{ display_time * 1000 }")
          system("#{ DEFAULTS[:client] } set message-fg #{ message_color }")
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

      # Notification starting, save the current Tmux settings
      # and quiet the Tmux output.
      #
      def turn_on(options = { })
        unless @options_stored
          reset_options_store

          `#{ DEFAULTS[:client] } show`.each_line do |line|
            option, _, setting = line.chomp.partition(' ')
            @options_store[option] = setting
          end

          @options_stored = true
        end

        system("#{ DEFAULTS[:client] } set quiet on")
      end

      # Notification stopping. Restore the previous Tmux state
      # if available (existing options are restored, new options
      # are unset) and unquite the Tmux output.
      #
      def turn_off(options = { })
        if @options_stored
          @options_store.each do |key, value|
            if value
              system("#{ DEFAULTS[:client] } set #{ key } #{ value }")
            else
              system("#{ DEFAULTS[:client] } set -u #{ key }")
            end
          end

          reset_options_store
        end

        system("#{ DEFAULTS[:client] } set quiet off")
      end

      private

      # Reset the internal Tmux options store defaults.
      #
      def reset_options_store
        @options_stored = false
        @options_store = {
          'status-left-bg'  => nil,
          'status-right-bg' => nil,
          'status-left-fg'  => nil,
          'status-right-fg' => nil,
          'message-bg'      => nil,
          'message-fg'      => nil,
          'display-time'    => nil
        }
      end

    end
  end
end
