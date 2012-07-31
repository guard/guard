module Guard
  module Notifier

    # System notifications using the [terminal_notifier](https://github.com/alloy/terminal-notifier gem.
    #
    # This gem is available for OS X 10.8 Mountain Lion and sends notifications to the OS X
    # notification center.
    #
    # @example Add the `terminal_notifier` gem to your `Gemfile`
    #   group :development
    #     gem 'terminal-notifier'
    #   end
    #
    # @example Add the `:terminal_notifier` notifier to your `Guardfile`
    #   notification :terminal_notifier
    #
    # @example Add the `:terminal_notifier` notifier with configuration options to your `Guardfile`
    #   notification :terminal_notifier, app_name: "MyApp"
    #
    module TerminalNotifier

      def self.available?(silent=false)
        begin
          require 'terminal-notifier'

          if ::TerminalNotifier.available?
            return true
          else
            ::Guard::UI.error 'The :terminal_notifier only runs on Mac OS X 10.8 and later.' unless silent
            false
          end
        rescue LoadError && NameError
          ::Guard::UI.error "Please add \"gem 'terminal_notifier'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
          false
        end
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image (ignored)
      # @param [Hash] options additional notification library options
      # @option options [String] app_name name of your app
      # @option options [String] execute a command
      # @option options [String] activate an app bundle
      # @option options [String] open some url or file
      #
      def self.notify(type, title, message, image, options = { })
        require 'terminal-notifier'
        options[:title] = [options[:app_name] || "Guard", type.downcase.capitalize, title].join " "
        options.delete :app_name if options[:app_name]
        ::TerminalNotifier.notify(message, options)
      end
    end
  end
end
