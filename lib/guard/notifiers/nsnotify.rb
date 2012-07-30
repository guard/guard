module Guard
  module Notifier

    # System notifications using the [nsnotify](https://github.com/foxycoder/nsnotify) gem.
    #
    # This gem is available for OS X 10.8 Mountain Lion and sends notifications to the OS X
    # notification center.
    #
    # @example Add the `nsnotify_guard` gem to your `Gemfile`
    #   group :development
    #     gem 'nsnotify_guard'
    #   end
    #
    # @example Add the `:nsnotify` notifier to your `Guardfile`
    #   notification :nsnotify
    #
    # @example Add the `:nsnotify` notifier with configuration options to your `Guardfile`
    #   notification :nsnotify_guard, app_name: "MyApp"
    #
    module Nsnotify
      extend self

      def available?(silent=false)
        require 'nsnotify'
        return true if ::Nsnotify.usable?
        ::Guard::UI.error 'The :nsnotify notifier only runs on Mac OS X 10.8 and later.' unless silent
      rescue LoadError
        ::Guard::UI.error "Please add \"gem 'nsnotify'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image (ignored)
      # @param [Hash] options additional notification library options
      # @option options [String] app_name name of your app
      #
      def notify(type, title, message, image, options = { })
        require 'nsnotify'
        full_title = [options[:app_name] || "Guard", type.downcase.capitalize, title].join " "
        ::Nsnotify.notify(full_title, message)
      end
    end
  end
end
