module Guard
  module UI
    class << self

      color_enabled = nil

      def info(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts reset_color(message) if message != ''
        end
      end

      def error(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts "#{color('ERROR:', ';31')} #{message}"
        end
      end

      def debug(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts "DEBUG: #{message}" if ::Guard.options && ::Guard.options[:debug]
        end
      end

      def reset_line
        print(color_enabled? ? "\r\e[0m" : "\r\n")
      end

      def clear
        system("clear;")
      end

    private

      def reset_color(text)
        color(text, "")
      end

      def color(text, color_code)
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
