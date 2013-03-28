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
        :client    => 'emacsclient',
        :success   => 'ForestGreen',
        :failed    => 'Firebrick',
        :default   => 'Black',
        :fontcolor => 'White',
      }

      # Test if Emacs with running server is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @param [Hash] options notifier options
      # @return [Boolean] the availability status
      #
      def available?(silent = false, options = {})
        result = `#{ options.fetch(:client, DEFAULTS[:client]) } --eval '1' 2> #{DEV_NULL} || echo 'N/A'`

        if %w(N/A 'N/A').include?(result.chomp!)
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
        options   = DEFAULTS.merge options
        color     = emacs_color type, options
        fontcolor = emacs_color :fontcolor, options
        elisp = <<-EOF.gsub(/\s+/, ' ').strip
          (set-face-attribute 'mode-line nil
               :background "#{color}"
               :foreground "#{fontcolor}")
        EOF
        run_cmd [ options[:client], '--eval', elisp ]
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

      private

      def run_cmd(args)
        IO.popen(args).readlines
      end
    end
  end
end
