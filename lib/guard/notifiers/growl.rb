require 'rbconfig'
require 'guard/ui'

module Guard
  module Notifier

    # System notifications using the [growl](https://github.com/visionmedia/growl) gem.
    #
    # This gem is available for OS X and sends system notifications to
    # [Growl](http://growl.info) through the [GrowlNotify](http://growl.info/downloads)
    # executable.
    #
    # The `growlnotify` executable must be installed manually or by using
    # [Homebrew](http://mxcl.github.com/homebrew/).
    #
    # Sending notifications with this notifier will not show the different
    # Guard notifications in the Growl preferences. Use the :gntp or :growl_notify
    # notifiers if you want to customize each notification type in Growl.
    #
    # @example Install `growlnotify` with Homebrew
    #   brew install growlnotify
    #
    # @example Add the `growl` gem to your `Gemfile`
    #   group :development
    #     gem 'growl'
    #   end
    #
    # @example Add the `:growl` notifier to your `Guardfile`
    #   notification :growl
    #
    # @example Add the `:growl_notify` notifier with configuration options to your `Guardfile`
    #   notification :growl, :sticky => true, :host => '192.168.1.5', :password => 'secret'
    #
    module Growl
      extend self

      # Default options for growl gem
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
          require 'growl'

          if ::Growl.installed?
            true
          else
            ::Guard::UI.error "Please install the 'growlnotify' executable." unless silent
            false
          end

        else
          ::Guard::UI.error 'The :growl notifier runs only on Mac OS X.' unless silent
          false
        end

      rescue LoadError, NameError
        ::Guard::UI.error "Please add \"gem 'growl'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # The documented options are for GrowlNotify 1.3, but the older options are
      # also supported. Please see `growlnotify --help`.
      #
      # Priority can be one of the following named keys: `Very Low`, `Moderate`, `Normal`,
      # `High`, `Emergency`. It can also be an int between -2 and 2.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [Boolean] sticky make the notification sticky
      # @option options [String, Integer] priority specify an int or named key (default is 0)
      # @option options [String] host the hostname or IP address to which to send a remote notification
      # @option options [String] password the password used for remote notifications
      #
      def notify(type, title, message, image, options = { })
        require 'growl'

        ::Growl.notify(message, DEFAULTS.merge(options).merge({
            :name => 'Guard',
            :title => title,
            :image => image
        }))
      end

    end
  end
end
