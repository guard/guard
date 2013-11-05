require 'guard/notifiers/base'

module Guard
  module Notifier

    # Send a notification to Emacs with emacsclient (http://www.emacswiki.org/emacs/EmacsClient).
    #
    # @example Add the `:emacs` notifier to your `Guardfile`
    #   notification :emacs
    #
    class Emacs < Base

      DEFAULTS = {
        client:    'emacsclient',
        success:   'ForestGreen',
        failed:    'Firebrick',
        default:   'Black',
        fontcolor: 'White',
      }

      def self.available?(opts = {})
        super and _emacs_client_available?(opts)
      end

      # @private
      #
      # @return [Boolean] whether or not the emacs client is available
      #
      def self._emacs_client_available?(opts)
        result = `#{opts.fetch(:client, DEFAULTS[:client])} --eval '1' 2> #{DEV_NULL} || echo 'N/A'`
        !%w(N/A 'N/A').include?(result.chomp!)
      end

      # Shows a system notification.
      #
      # @param [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] opts additional notification library options
      # @option opts [String] success the color to use for success
      #   notifications (default is 'ForestGreen')
      # @option opts [String] failed the color to use for failure
      #   notifications (default is 'Firebrick')
      # @option opts [String] pending the color to use for pending
      #   notifications
      # @option opts [String] default the default color to use (default is
      #   'Black')
      # @option opts [String] client the client to use for notification
      #   (default is 'emacsclient')
      # @option opts [String, Integer] priority specify an int or named key
      #   (default is 0)
      #
      def notify(message, opts = {})
        super

        opts      = DEFAULTS.merge(opts)
        color     = emacs_color(opts[:type], opts)
        fontcolor = emacs_color(:fontcolor, opts)
        elisp = <<-EOF.gsub(/\s+/, ' ').strip
          (set-face-attribute 'mode-line nil
               :background "#{color}"
               :foreground "#{fontcolor}")
        EOF

        _run_cmd(opts[:client], '--eval', elisp)
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
        default = options.fetch(:default, DEFAULTS[:default])
        options.fetch(type.to_sym, default)
      end

      private

      def _run_cmd(*args)
        p = IO.popen(args)
        p.readlines
        p.close
      end

    end

  end
end
