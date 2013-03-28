require 'rbconfig'
require 'guard/ui'

module Guard
  module Notifier

    # System notifications using the [ruby_gntp](https://github.com/snaka/ruby_gntp) gem.
    #
    # This gem is available for OS X, Linux and Windows and sends system notifications to
    # the following system notification frameworks through the
    # [Growl Network Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx):
    #
    # * [Growl](http://growl.info)
    # * [Growl for Windows](http://www.growlforwindows.com)
    # * [Growl for Linux](http://mattn.github.com/growl-for-linux)
    # * [Snarl](https://sites.google.com/site/snarlapp/)
    #
    # @example Add the `ruby_gntp` gem to your `Gemfile`
    #   group :development
    #     gem 'ruby_gntp'
    #   end
    #
    # @example Add the `:gntp` notifier to your `Guardfile`
    #   notification :gntp
    #
    # @example Add the `:gntp` notifier with configuration options to your `Guardfile`
    #   notification :gntp, :sticky => true, :host => '192.168.1.5', :password => 'secret'
    #
    module GNTP
      extend self

      # Default options for the ruby gtnp gem
      DEFAULTS = {
        :sticky   => false,
        :host     => '127.0.0.1',
        :password => '',
        :port     => 23053
      }

      # Is this notifier already registered
      #
      # @return [Boolean] registration status
      #
      def registered?
        @registered ||= false
      end

      # Mark the notifier as registered.
      #
      def registered!
        @registered = true
      end

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @param [Hash] options notifier options
      # @return [Boolean] the availability status
      #
      def available?(silent = false, options = {})
        if RbConfig::CONFIG['host_os'] =~ /darwin|linux|freebsd|openbsd|sunos|solaris|mswin|mingw|cygwin/
          require 'ruby_gntp'
          true

        else
          ::Guard::UI.error 'The :gntp notifier runs only on Mac OS X, Linux, FreeBSD, OpenBSD, Solaris and Windows.' unless silent
          false
        end

      rescue LoadError
        ::Guard::UI.error "Please add \"gem 'ruby_gntp'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [String] host the hostname or IP address to which to send a remote notification
      # @option options [String] password the password used for remote notifications
      # @option options [Integer] port the port to send a remote notification
      # @option options [Boolean] sticky make the notification sticky
      #
      def notify(type, title, message, image, options = { })
        require 'ruby_gntp'

        options = DEFAULTS.merge(options)

        gntp = ::GNTP.new('Guard', options.delete(:host), options.delete(:password), options.delete(:port))

        unless registered?
          gntp.register({
              :app_icon => File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'images', 'guard.png')),
              :notifications => [
                  { :name => 'notify', :enabled => true },
                  { :name => 'failed', :enabled => true },
                  { :name => 'pending', :enabled => true },
                  { :name => 'success', :enabled => true }
              ]
          })

          registered!
        end

        gntp.notify(options.merge({
            :name  => type,
            :title => title,
            :text  => message,
            :icon  => image
        }))
      end

    end
  end
end

