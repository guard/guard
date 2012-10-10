require 'rbconfig'

module Guard
  module Notifier

    # Send a notification to Emacs with emacsclient (http://www.emacswiki.org/emacs/EmacsClient).
    #
    # @example Add the `:emacs` notifier to your `Guardfile`
    #   notification :emacs
    #
    module Emacs
      extend self

      DEFAULTS = {
        :client  => 'emacsclient',
        :success => 'ForestGreen',
        :failed  => 'Firebrick',
        :default => 'Black',
      }

      # Test if Emacs with running server is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        result = `#{ DEFAULTS[:client] } --eval '1' 2> /dev/null || echo 'N/A'`

        if result.chomp! == 'N/A'
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
      # @option options [String] success the color to use for success notifications (default is 'ForestGreen')
      # @option options [String] failed the color to use for failure notifications (default is 'Firebrick')
      # @option options [String] pending the color to use for pending notifications
      # @option options [String] default the default color to use (default is 'Black')
      # @option options [String] client the client to use for notification (default is 'emacsclient')
      # @option options [String, Integer] priority specify an int or named key (default is 0)
      #
      def notify(type, title, message, image, options = { })
        options = DEFAULTS.merge options
        color   = emacs_color type, options
        system(%(#{ options[:client] } --eval "(set-face-background 'modeline \\"#{ color }\\")"))
      end

      # Get the Emacs color for the notification type.
      # You can configure your own color by overwrite the defaults.
      #
      # @param [String] type the notification type
      # @param [Hash] options aditional notification options
      # @option options [String] success the color to use for success notifications (default is 'ForestGreen')
      # @option options [String] failed the color to use for failure notifications (default is 'Firebrick')
      # @option options [String] pending the color to use for pending notifications
      # @option options [String] default the default color to use (default is 'Black')
      # @return [String] the name of the emacs color
      #
      def emacs_color(type, options = {})
        default = options[:default] || DEFAULTS[:default]
        options.fetch(type.to_sym, default)
      end
    end
  end
end
