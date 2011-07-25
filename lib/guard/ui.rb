module Guard
  module UI

    ANSI_ESCAPE_BRIGHT = "1"

    ANSI_ESCAPE_BLACK = "30"
    ANSI_ESCAPE_RED = "31"
    ANSI_ESCAPE_GREEN = "32"
    ANSI_ESCAPE_YELLOW = "33"
    ANSI_ESCAPE_BLUE = "34"
    ANSI_ESCAPE_MAGENTA = "35"
    ANSI_ESCAPE_CYAN = "36"
    ANSI_ESCAPE_WHITE = "37"

    ANSI_ESCAPE_BGBLACK = "40"
    ANSI_ESCAPE_BGRED = "41"
    ANSI_ESCAPE_BGGREEN = "42"
    ANSI_ESCAPE_BGYELLOW = "43"
    ANSI_ESCAPE_BGBLUE = "44"
    ANSI_ESCAPE_BGMAGENTA = "45"
    ANSI_ESCAPE_BGCYAN = "46"
    ANSI_ESCAPE_BGWHITE = "47"

    class << self

      color_enabled = nil

      def info(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts color(message) if message != ''
        end
      end

      def error(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts color('ERROR: ', :red) + message
        end
      end

      def deprecation(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts color('DEPRECATION: ', :red) + message
        end
      end

      def debug(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts color("DEBUG (#{Time.now.strftime('%T')}): ", :yellow) + message if ::Guard.options && ::Guard.options[:debug]
        end
      end

      def reset_line
        print(color_enabled? ? "\r\e[0m" : "\r\n")
      end

      def clear
        system("clear;")
      end

    private

      # @deprecated
      def reset_color(text)
        deprecation('UI.reset_color(text) is deprecated, please use color(text, "") instead.')
        color(text, "")
      end

      def color(text, *color_options)
        color_code = ""
        color_options.each do |color_option|
          color_option = color_option.to_s
          if color_option != ""
            if !(color_option =~ /\d+/)
              color_option = const_get("ANSI_ESCAPE_#{color_option.upcase}")
            end
            color_code += ";" + color_option
          end
        end
        color_enabled? ? "\e[0#{color_code}m#{text}\e[0m" : text
      end

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

    end
  end
end
