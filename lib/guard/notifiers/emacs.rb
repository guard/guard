require 'rbconfig'

module Guard
  module Notifier

    DEFAULTS = {
      :client => 'emacsclient',
      :success => 'ForestGreen',
      :failed => 'Firebrick',
      :default => 'Black',
    }

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
        result = `#{DEFAULTS[:client]} --eval '1' 2> /dev/null || echo 0`

        if result.chomp! == "1"
          true
        else
          false
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
