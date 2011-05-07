module Guard
  module UI
    class << self

      def info(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts reset_color(message) if message != ''
        end
      end

      def error(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts "ERROR: #{message}"
        end
      end

      def debug(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts "DEBUG: #{message}" if ::Guard.options && ::Guard.options[:debug]
        end
      end

      def reset_line
        if color_enabled?
          print "\r\e[0m"
        else
          print "\r\n"
        end
      end

      def clear
        system("clear;")
      end

    private

      def reset_color(text)
        color(text, "\e[0m")
      end

      def color(text, color_code)
        if color_enabled?
          return "#{color_code}#{text}\e[0m"
        else
          return text
        end
      end

      def color_enabled?
        @color_enabled ||= if Config::CONFIG['target_os'] =~ /mswin|mingw/i
          unless ENV['ANSICON']
            begin
              require 'rubygems' unless ENV['NO_RUBYGEMS']
              require 'Win32/Console/ANSI'
            rescue LoadError
              info "You must 'gem install win32console' to use color on Windows"
              false
            end
          end
        else
          true
        end
      end

    end
  end
end
