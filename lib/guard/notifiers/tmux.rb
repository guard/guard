require 'guard/notifiers/base'

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

      # Default options for the tmux notifications.
      DEFAULTS = {
        client:                 'tmux',
        tmux_environment:       'TMUX',
        success:                'green',
        failed:                 'red',
        pending:                'yellow',
        default:                'green',
        timeout:                5,
        display_message:        false,
        default_message_format: '%s - %s',
        default_message_color:  'white',
        display_on_all_clients: false,
        display_title:          false,
        default_title_format:   '%s - %s',
        line_separator:         ' - ',
        change_color:           true,
        color_location:         'status-left-bg'
      }

      def self.available?(opts = {})
        super and _register!(opts)
      end

      # @private
      #
      # @return [Boolean] whether or not a TMUX environment is available
      #
      def self._tmux_environment_available?(opts)
        !ENV[opts.fetch(:tmux_environment, DEFAULTS[:tmux_environment])].nil?
      end

      # @private
      #
      # Detects if a TMUX environment is available and if not,
      # displays an error message unless `opts[:silent]` is true.
      #
      # @return [Boolean] whether or not a TMUX environment is available
      #
      def self._register!(opts)
        if _tmux_environment_available?(opts)
          true
        else
          unless opts[:silent]
            ::Guard::UI.error 'The :tmux notifier runs only on when Guard is executed inside of a tmux session.'
          end
          false
        end
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
      # @param [String] title the notification title
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] message the notification message body
      # @option opts [String] image the path to the notification image
      # @option opts [Boolean] change_color whether to show a color
      #   notification
      # @option opts [String,Array] color_location the location where to draw the
      #   color notification
      # @option opts [Boolean] display_message whether to display a message
      #   or not
      # @option opts [Boolean] display_on_all_clients whether to display a
      #   message on all tmux clients or not
      #
      def notify(message, opts = {})
        super
        opts.delete(:image)

        if opts.fetch(:change_color, DEFAULTS[:change_color])
          color_locations = Array(opts.fetch(:color_location, DEFAULTS[:color_location]))
          color = tmux_color(opts[:type], opts)

          color_locations.each do |color_location|
            _run_client "set","-q #{ color_location } #{ color }"
          end
        end

        type  = opts.delete(:type).to_s
        title = opts.delete(:title)

        if opts.fetch(:display_title, DEFAULTS[:display_title])
          display_title(type, title, message, opts)
        end

        if opts.fetch(:display_message, DEFAULTS[:display_message])
          display_message(type, title, message, opts)
        end
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
      def display_title(type, title, message, opts = {})
        title_format   = opts.fetch("#{ type }_title_format".to_sym, opts.fetch(:default_title_format, DEFAULTS[:default_title_format]))
        teaser_message = message.split("\n").first
        display_title  = title_format % [title, teaser_message]

        if _tmux_version >= 1.7
          _run_client "set-option", "-q set-titles-string '#{ display_title }'"
        else
          _run_client "set-option", "set-titles-string '#{ display_title }'"
        end
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
        message_format = opts.fetch("#{ type }_message_format".to_sym, opts.fetch(:default_message_format, DEFAULTS[:default_message_format]))
        message_color = opts.fetch("#{ type }_message_color".to_sym, opts.fetch(:default_message_color, DEFAULTS[:default_message_color]))
        display_time = opts.fetch(:timeout, DEFAULTS[:timeout])
        separator = opts.fetch(:line_separator, DEFAULTS[:line_separator])

        color = tmux_color type, opts
        formatted_message = message.split("\n").join(separator)
        display_message = message_format % [title, formatted_message]

        _run_client "set", "-q display-time #{ display_time * 1000 }"
        _run_client "set", "-q message-fg #{ message_color }"
        _run_client "set", "-q message-bg #{ color }"
        _run_client "display-message", "'#{ display_message }'"
     end

      # Get the Tmux color for the notification type.
      # You can configure your own color by overwriting the defaults.
      #
      # @param [String] type the notification type
      # @return [String] the name of the emacs color
      #
      def tmux_color(type, opts = {})
        type = type.to_sym
        type = :default unless [:success, :failed, :pending].include?(type)

        opts.fetch(type, DEFAULTS[type])
      end

      # Notification starting, save the current Tmux settings
      # and quiet the Tmux output.
      #
      def self.turn_on
        unless @options_stored
          _reset_options_store

          _clients.each do |client|
            options_store[client] ||= {}
            `#{ DEFAULTS[:client] } show -t #{ client }`.each_line do |line|
              option, _, setting = line.chomp.partition(' ')
              @options_store[client][option] = setting
            end
          end

          @options_stored = true
        end
      end

      # Notification stopping. Restore the previous Tmux state
      # if available (existing options are restored, new options
      # are unset) and unquiet the Tmux output.
      #
      def self.turn_off
        if @options_stored
          @options_store.each do |client, options|
            options.each do |key, value|
              if value
                `#{ DEFAULTS[:client] } set -t #{ client } -q #{ key } #{ value }`
              else
                `#{ DEFAULTS[:client] } set -t #{ client } -q -u #{ key }`
              end
            end
          end
          _reset_options_store
        end
      end

      def self.options_store
        @options_store ||= {}
      end

      private

      def system(args)
        args += " >#{ DEV_NULL } 2>&1" if ENV['GUARD_ENV'] == 'test'
        super
      end

      def self._clients
        `#{ DEFAULTS[:client] } list-clients -F '\#{ client_tty }'`.split(/\n/)
      end

      def _clients
        self.class._client
      end

      def _run_client(cmd, args)
        if @options.fetch(:display_on_all_clients, DEFAULTS[:display_on_all_clients])
          _clients.each do |client|
            system("#{ DEFAULTS[:client] } #{ cmd } #{ _client_cmd_flag(cmd) } #{ client.strip } #{ args }")
          end
        else
          system("#{ DEFAULTS[:client] } #{ cmd } #{ args }")
        end
      end

      def _client_cmd_flag(cmd)
        case cmd
          when 'set', 'set-option' then '-t'
          when 'display-message' then '-c'
        end
      end

      # Reset the internal Tmux options store defaults.
      #
      def self._reset_options_store
        @options_stored = false
        @options_store = {}

        _clients.each do |client|
          @options_store[client] = {
            'status-left-bg'  => nil,
            'status-right-bg' => nil,
            'status-left-fg'  => nil,
            'status-right-fg' => nil,
            'message-bg'      => nil,
            'message-fg'      => nil,
            'display-time'    => nil
          }
        end
      end

      def _tmux_version
        @tmux_version ||= `tmux -V`.chomp.gsub(/[^0-9.]/, '').to_f
      end

    end

  end
end
