require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using the [GrowlNotify](https://github.com/scottdavis/growl_notify) gem.
    #
    # This gem is available for OS X and sends system notifications to
    # [Growl](http://growl.info) through AppleScript.
    #
    # @example Add the `growl_notify` gem to your `Gemfile`
    #   group :development
    #     gem 'growl_notify'
    #   end
    #
    # @example Add the `:growl_notify` notifier to your `Guardfile`
    #   notification :growl_notify
    #
    # @example Add the `:growl_notify` notifier with configuration options to your `Guardfile`
    #   notification :growl_notify, sticky: true
    #
    class GrowlNotify < Base

      # Default options for the growl_notify notifications.
      DEFAULTS = {
        sticky:   false,
        priority: 0
      }

      def self.supported_hosts
        %w[darwin]
      end

      def self.available?(opts = {})
        super and require_gem_safely(opts) and _register!(opts)
      end

      # @private
      #
      # Detects if the GrowlNotify gem is available and if not, displays an
      # error message unless `opts[:silent]` is true. If it's available,
      # GrowlNotify is configured for Guard.
      #
      # @return [Boolean] whether or not GrowlNotify is available
      #
      def self._register!(options)
        if ::GrowlNotify.application_name != 'Guard'
          ::GrowlNotify.config do |c|
            c.notifications         = %w(success pending failed notify)
            c.default_notifications = 'notify'
            c.application_name      = 'Guard'
          end
        end

        true

      rescue ::GrowlNotify::GrowlNotFound
        unless options[:silent]
          ::Guard::UI.error 'Please install Growl from http://growl.info'
        end
        false
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [Boolean] sticky if the message should stick to the screen
      # @option opts [Integer] priority the importance of message from -2 (very
      #   low) to 2 (emergency)
      #
      def notify(message, opts = {})
        super
        self.class.require_gem_safely

        opts = DEFAULTS.merge(
          application_name: 'Guard',
          with_name:        opts.delete(:type).to_s,
          description:      message,
          icon:             opts.delete(:image)
        ).merge(opts)

        ::GrowlNotify.send_notification(opts)
      end

    end

  end
end
