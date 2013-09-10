require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using the
    # [terminal-notifier-guard](https://github.com/Springest/terminal-notifier-guard)
    # gem.
    #
    # This gem is available for OS X 10.8 Mountain Lion and sends notifications
    # to the OS X notification center.
    #
    # @example Add the `terminal-notifier-guard` gem to your `Gemfile`
    #   group :development
    #     gem 'terminal-notifier-guard'
    #   end
    #
    # @example Add the `:terminal_notifier` notifier to your `Guardfile`
    #   notification :terminal_notifier
    #
    # @example Add the `:terminal_notifier` notifier with configuration options to your `Guardfile`
    #   notification :terminal_notifier, app_name: "MyApp"
    #
    class TerminalNotifier < Base

      def self.supported_hosts
        %w[darwin]
      end

      def self.gem_name
        'terminal-notifier-guard'
      end

      def self.available?(opts = {})
        super
        _register!(opts) if require_gem_safely(opts)
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image (ignored)
      # @option opts [String] app_name name of your app
      # @option opts [String] execute a command
      # @option opts [String] activate an app bundle
      # @option opts [String] open some url or file
      #
      def notify(message, opts = {})
        self.class.require_gem_safely
        title = opts[:title]
        normalize_standard_options!(opts)

        opts.delete(:image)
        opts[:title] = title || [opts.delete(:app_name) { 'Guard' }, opts[:type].downcase.capitalize].join(' ')

        ::TerminalNotifier::Guard.execute(false, opts.merge(message: message))
      end

      # @private
      #
      def self._register!(options)
        if ::TerminalNotifier::Guard.available?
          true
        else
          unless options[:silent]
            ::Guard::UI.error 'The :terminal_notifier only runs on Mac OS X 10.8 and later.'
          end
          false
        end
      end

    end

  end
end
