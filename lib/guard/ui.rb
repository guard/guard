module Guard

  # The UI class helps to format messages for the user.
  #
  module UI
    class << self

      color_enabled = nil

      # Show an info message.
      #
      # @param [String] message the message to show
      # @param [Hash] options the options
      # @option options [Boolean] reset whether to clean the output before
      #
      def info(message, options = { })
        unless ENV['GUARD_ENV'] == 'test'
          reset_line if options[:reset]
          puts color(message) if message != ''
        end
      end

      # Show a red error message that is prefixed with ERROR.
      #
      # @param [String] message the message to show
      # @param [Hash] options the options
      # @option options [Boolean] reset whether to clean the output before
      #
      def error(message, options = { })
        unless ENV['GUARD_ENV'] == 'test'
          reset_line if options[:reset]
          puts color('ERROR: ', :red) + message
        end
      end

      # Show a red deprecation message that is prefixed with DEPRECATION.
      #
      # @param [String] message the message to show
      # @param [Hash] options the options
      # @option options [Boolean] reset whether to clean the output before
      #
      def deprecation(message, options = { })
        unless ENV['GUARD_ENV'] == 'test'
          reset_line if options[:reset]
          puts color('DEPRECATION: ', :red) + message
        end
      end

      # Show a debug message that is prefixed with DEBUG and a timestamp.
      #
      # @param [String] message the message to show
      # @param [Hash] options the options
      # @option options [Boolean] reset whether to clean the output before
      #
      def debug(message, options = { })
        unless ENV['GUARD_ENV'] == 'test'
          reset_line if options[:reset]
          puts color("DEBUG (#{Time.now.strftime('%T')}): ", :yellow) + message if ::Guard.options && ::Guard.options[:debug]
        end
      end

      # Reset a line.
      #
      def reset_line
        print(color_enabled? ? "\r\e[0m" : "\r\n")
      end

      # Clear the output.
      #
      def clear
        system('clear;')
      end

      private

      # Reset a color sequence.
      #
      # @deprecated
      # @param [String] text the text
      #
      def reset_color(text)
        deprecation('UI.reset_color(text) is deprecated, please use color(text, ' ') instead.')
        color(text, '')
      end

      # Checks if color output can be enabled.
      #
      # @return [Boolean] whether color is enabled or not
      #
      def color_enabled?
        if @color_enabled.nil?
          if RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
            if ENV['ANSICON']
              @color_enabled = true
            else
              begin
                require 'rubygems' unless ENV['NO_RUBYGEMS']
                require 'Win32/Console/ANSI'
                @color_enabled = true
              rescue LoadError
                @color_enabled = false
                info "You must 'gem install win32console' to use color on Windows"
              end
            end
          else
            @color_enabled = true
          end
        end

        @color_enabled
      end

      # Colorizes a text message. See the constant below for possible
      # color_options parameters. You can pass :bright, a foreground
      # and a background color.
      #
      # @example
      #   color('Hello World', :red, :bright)
      #
      # @param [String] the text to colorize
      # @param [Array] color_options the color options
      #
      def color(text, *color_options)
        color_code = ''
        color_options.each do |color_option|
          color_option = color_option.to_s
          if color_option != ''
            if !(color_option =~ /\d+/)
              color_option = const_get("ANSI_ESCAPE_#{ color_option.upcase }")
            end
            color_code += ';' + color_option
          end
        end
        color_enabled? ? "\e[0#{ color_code }m#{ text }\e[0m" : text
      end

    end

    # bright color
    ANSI_ESCAPE_BRIGHT    = '1'

    # black foreground color
    ANSI_ESCAPE_BLACK     = '30'

    # red foreground color
    ANSI_ESCAPE_RED       = '31'

    # green foreground color
    ANSI_ESCAPE_GREEN     = '32'

    # yellow foreground color
    ANSI_ESCAPE_YELLOW    = '33'

    # blue foreground color
    ANSI_ESCAPE_BLUE      = '34'

    # magenta foreground color
    ANSI_ESCAPE_MAGENTA   = '35'

    # cyan foreground color
    ANSI_ESCAPE_CYAN      = '36'

    # white foreground color
    ANSI_ESCAPE_WHITE     = '37'

    # black background color
    ANSI_ESCAPE_BGBLACK   = '40'

    # red background color
    ANSI_ESCAPE_BGRED     = '41'

    # green background color
    ANSI_ESCAPE_BGGREEN   = '42'

    # yellow background color
    ANSI_ESCAPE_BGYELLOW  = '43'

    # blue background color
    ANSI_ESCAPE_BGBLUE    = '44'

    # magenta background color
    ANSI_ESCAPE_BGMAGENTA = '45'

    # cyan background color
    ANSI_ESCAPE_BGCYAN    = '46'

    # white background color
    ANSI_ESCAPE_BGWHITE   = '47'

  end
end
