module Guard
  module UI
    class << self

      @color_enabled = true
      @color_tested = false
      @new_line = "\r"

      def color_enabled?
        if !@color_tested
          @color_tested = true
          if Config::CONFIG['target_os'] =~ /mswin|mingw/i
            @new_line = "\r\n"
            unless ENV['ANSICON']
              begin
                require 'rubygems' unless ENV['NO_RUBYGEMS']
                require 'Win32/Console/ANSI'              
              rescue LoadError
                @color_enabled = false
                info "You must 'gem install win32console' to use color on Windows"              
              end
            end
          end
        end
        return @color_enabled
      end
      
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
          print @new_line + "\e[0m"
        else
          print @new_line
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

    end
  end
end
