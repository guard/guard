require 'rbconfig'
require 'guard/ui'

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
    #   notification :growl_notify, :sticky => true
    #
    module GrowlNotify
      extend self

      # Default options for growl_notify gem
      DEFAULTS = {
        :sticky   => false,
        :priority => 0
      }

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @param [Hash] options notifier options
      # @return [Boolean] the availability status
      #
      def available?(silent = false, options = {})
        if RbConfig::CONFIG['host_os'] =~ /darwin/
          require 'growl_notify'

          begin
            if ::GrowlNotify.application_name != 'Guard'
              ::GrowlNotify.config do |c|
                c.notifications         = %w(success pending failed notify)
                c.default_notifications = 'notify'
                c.application_name      = 'Guard'
              end
            end

            true

          rescue ::GrowlNotify::GrowlNotFound
            ::Guard::UI.error 'Please install Growl from http://growl.info' unless silent
            false
          end

        else
          ::Guard::UI.error 'The :growl_notify notifier runs only on Mac OS X.' unless silent
          false
        end

      rescue LoadError, NameError
        ::Guard::UI.error "Please add \"gem 'growl_notify'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [Boolean] sticky if the message should stick to the screen
      # @option options [Integer] priority the importance of message from -2 (very low) to 2 (emergency)
      #
      def notify(type, title, message, image, options = { })
        require 'growl_notify'

        ::GrowlNotify.send_notification(DEFAULTS.merge(options).merge({
            :application_name => 'Guard',
            :with_name        => type,
            :title            => title,
            :description      => message,
            :icon             => image
        }))
      end

    end
  end
end

