require 'rbconfig'

module Guard
  module Notifier

    # Default options for EmacsClient
    DEFAULTS = {
      :client => 'emacsclient',
      :success => 'ForestGreen',
      :failed => 'Firebrick',
      :default => 'Black',
    }

    # Send a notification to Emacs with emacsclient (http://www.emacswiki.org/emacs/EmacsClient).
    #
    # @example Add the `:emacs` notifier to your `Guardfile`
    #   notification :emacs
    #
    module Emacs
      extend self

      # Test if Emacs with running server is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        result = `#{DEFAULTS[:client]} --eval '1' 2> /dev/null || echo 'N/A'`

        if result.chomp! == "N/A"
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
        system(%(#{DEFAULTS[:client]} --eval "(set-face-background 'modeline \\"#{emacs_color(type)}\\")"))
      end

      # Get the Emacs color for the notification type.
      # You can configure your own color by overwrite the defaults.
      #
      # @param [String] type the notification type
      # @return [String] the name of the emacs color
      #
      def emacs_color(type)
        case type
            when 'success'
              DEFAULTS[:success]
            when 'failed'
              DEFAULTS[:failed]
            else
              DEFAULTS[:default]
        end
      end
    end
  end
end
