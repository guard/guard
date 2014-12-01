require "guard/notifiers/base"
require "guard/sheller"

module Guard
  module Notifier
    # Changes the color of the Tmux status bar and optionally
    # shows messages in the status bar.
    #
    # @example Add the `:tmux` notifier to your `Guardfile`
    #   notification :tmux
    #
    # @example Enable text messages
    #   notification :tmux, display_message: true
    #
    # @example Customize the tmux status colored for notifications
    #   notification :tmux, color_location: 'status-right-bg'
    #
    class Tmux < Base
      @@session = nil

      # Default options for the tmux notifications.
      class Defaults
        DEFAULTS = {
          tmux_environment:       "TMUX",
          success:                "green",
          failed:                 "red",
          pending:                "yellow",
          default:                "green",
          timeout:                5,
          display_message:        false,
          default_message_format: "%s - %s",
          default_message_color:  "white",
          display_on_all_clients: false,
          display_title:          false,
          default_title_format:   "%s - %s",
          line_separator:         " - ",
          change_color:           true,
          color_location:         "status-left-bg"
        }

        def self.option(opts, name)
          opts.fetch(name, DEFAULTS[name])
        end

        def self.[](name)
          DEFAULTS[name]
        end
      end

      class Client
        CLIENT = "tmux"
        class << self
          def version
            Float(_capture("-V")[/\d+\.\d+/])
          end

          def clients
            ttys = _capture("list-clients", "-F", "'\#{client_tty}'")
            ttys = ttys.split(/\n/)

            # if user is running 'tmux -C' remove this client from list
            ttys.delete("(null)")
            ttys
          end

          def set(client, key, value)
            case client
            when :all, true
              # call ourself
              clients.each { |cl| Client.set(cl, key, value) }
            else
              args = client ? ["-t", client.strip] : nil
              _run("set", "-q", *args, key, value)
            end
          end

          def display(client, message)
            case client
            when :all, true
              # call ourself
              clients.each { |cl| Client.display(cl, message) }
            else
              args += ["-c", client.strip] if client
              _run("display", *args, message)
            end
          end

          def unset(client, key, value)
            return set(client, key, value) if value
            args = client ? ["-t", client.strip] : []
            _run("set", "-q", "-u", *args, key)
          end

          def parse_options(client)
            output = _capture("show", "-t", client)
            Hash[output.lines.map { |line| _parse_option(line) }]
          end

          def _parse_option(line)
            line.partition(" ").map(&:strip).reject(&:empty?)
          end

          def _capture(*args)
            Sheller.stdout(([CLIENT] + args).join(" "))
          end

          def _run(*args)
            Sheller.run(([CLIENT] + args).join(" "))
          end
        end
      end

      class Session
        def initialize(_tmux)
          @options_store = {}

          Client.clients.each do |client|
            @options_store[client] = {
              "status-left-bg"  => nil,
              "status-right-bg" => nil,
              "status-left-fg"  => nil,
              "status-right-fg" => nil,
              "message-bg"      => nil,
              "message-fg"      => nil,
              "display-time"    => nil
            }.merge(Client.parse_options(client))
          end
        end

        def close
          @options_store.each do |client, options|
            options.each do |key, value|
              Client.unset(client, key, value)
            end
          end
          @options_store = nil
        end
      end

      class Error < RuntimeError
      end

      ERROR_NOT_INSIDE_TMUX = "The :tmux notifier runs only on when Guard"\
              " is executed inside of a tmux session."

      ERROR_ANCIENT_TMUX = "Your tmux version is way too old!"

      def self.available?(opts = {})
        return unless super

        fail "PREVIOUS TMUX SESSION NOT CLEARED!" if @@session || nil

        var_name = Defaults.option(opts, :tmux_environment)
        fail Error, ERROR_NOT_INSIDE_TMUX unless ENV.key?(var_name)

        version = Client.version
        fail Error, format(ERROR_ANCIENT_TMUX, version) if version < 1.7

        true
      rescue Error => e
        ::Guard::UI.error e.message unless opts[:silent]
        false
      end

      # Shows a system notification.
      #
      # By default, the Tmux notifier only makes
      # use of a color based notification, changing the background color of the
      # `color_location` to the color defined in either the `success`,
      # `failed`, `pending` or `default`, depending on the notification type.
      #
      # You may enable an extra explicit message by setting `display_message`
      # to true, and may further disable the colorization by setting
      # `change_color` to false.
      #
      # @param [String] message the notification message
      # @param [Hash] options additional notification library options
      # @option options [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option options [String] message the notification message body
      # @option options [String] image the path to the notification image
      # @option options [Boolean] change_color whether to show a color
      #   notification
      # @option options [String,Array] color_location the location where to draw
      #   the color notification
      # @option options [Boolean] display_message whether to display a message
      #   or not
      # @option options [Boolean] display_on_all_clients whether to display a
      #   message on all tmux clients or not
      #
      def notify(message, options = {})
        super
        options.delete(:image)

        change_color = Defaults.option(options, :change_color)
        locations = Array(Defaults.option(options, :color_location))
        display_the_title = Defaults.option(options, :display_title)
        display_message = Defaults.option(options, :display_message)
        type  = options.delete(:type).to_s
        title = options.delete(:title)

        if change_color
          color = tmux_color(type, options)
          locations.each { |location| Client.set(_all?, location, color) }
        end

        display_title(type, title, message, options) if display_the_title

        return unless display_message
        display_message(type, title, message, options)
      end

      # Displays a message in the title bar of the terminal.
      #
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [Hash] options additional notification library options
      # @option options [String] success_message_format a string to use as
      #   formatter for the success message.
      # @option options [String] failed_message_format a string to use as
      #   formatter for the failed message.
      # @option options [String] pending_message_format a string to use as
      #   formatter for the pending message.
      # @option options [String] default_message_format a string to use as
      #   formatter when no format per type is defined.
      #
      def display_title(type, title, message, options = {})
        format = "#{type}_title_format".to_sym
        default_title_format = Defaults.option(options, :default_title_format)
        title_format   = options.fetch(format, default_title_format)
        teaser_message = message.split("\n").first
        display_title  = title_format % [title, teaser_message]

        Client.set(_all?, "set-titles-string", "'#{display_title}'")
      end

      # Displays a message in the status bar of tmux.
      #
      # @param [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [Hash] options additional notification library options
      # @option options [Integer] timeout the amount of seconds to show the
      #   message in the status bar
      # @option options [String] success_message_format a string to use as
      #   formatter for the success message.
      # @option options [String] failed_message_format a string to use as
      #   formatter for the failed message.
      # @option options [String] pending_message_format a string to use as
      #   formatter for the pending message.
      # @option options [String] default_message_format a string to use as
      #   formatter when no format per type is defined.
      # @option options [String] success_message_color the success notification
      #   foreground color name.
      # @option options [String] failed_message_color the failed notification
      #   foreground color name.
      # @option options [String] pending_message_color the pending notification
      #   foreground color name.
      # @option options [String] default_message_color a notification
      #   foreground color to use when no color per type is defined.
      # @option options [String] line_separator a string to use instead of a
      #   line-break.
      #
      def display_message(type, title, message, opts = {})
        default_format = Defaults.option(opts, :default_message_format)
        default_color = Defaults.option(opts, :default_message_color)
        display_time = Defaults.option(opts, :timeout)
        separator = Defaults.option(opts, :line_separator)

        format = "#{type}_message_format".to_sym
        message_format = opts.fetch(format, default_format)

        color = "#{type}_message_color".to_sym
        message_color = opts.fetch(color, default_color)

        color = tmux_color(type, opts)
        formatted_message = message.split("\n").join(separator)
        display_message = message_format % [title, formatted_message]

        Client.set(_all?, "display-time", display_time * 1000)
        Client.set(_all?, "message-fg", message_color)
        Client.set(_all?, "message-bg", color)
        Client.display(_all?, "'#{display_message}'")
      end

      # Get the Tmux color for the notification type.
      # You can configure your own color by overwriting the defaults.
      #
      # @param [String] type the notification type
      # @return [String] the name of the emacs color
      #
      def tmux_color(type, opts = {})
        type = type.to_sym
        opts[type] || Defaults[type] || Defaults.option(opts, :default)
      end

      # Notification starting, save the current Tmux settings
      # and quiet the Tmux output.
      #
      def self.turn_on
        _start_session
      end

      # Notification stopping. Restore the previous Tmux state
      # if available (existing options are restored, new options
      # are unset) and unquiet the Tmux output.
      #
      def self.turn_off
        _end_session
      end

      private

      def self._start_session
        fail "Already turned on!" if @@session
        @@session = Session.new(self)
      end

      def self._end_session
        fail "Already turned off!" unless @@session || nil
        @@session.close
        @@session = nil
      end

      def self._session
        @@session
      end

      def _all?
        Defaults.option(options, :display_on_all_clients)
      end
    end
  end
end
