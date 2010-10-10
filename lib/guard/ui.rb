module Guard
  module UI
    class << self
      
      def info(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts reset_color(message) if message != ''
        end
      end
      
      def error(message)
        puts "ERROR: #{message}"
      end
      
      def debug(message)
        unless ENV["GUARD_ENV"] == "test"
          puts "DEBUG: #{message}" if ::Guard.options && ::Guard.options[:debug]
        end
      end
      
      def reset_line
        print "\r\e "
      end
      
      def clear
        system("clear;")
      end
      
    private
      
      def reset_color(text)
        color(text, "\e[0m")
      end
      
      def color(text, color_code)
        "#{color_code}#{text}\e[0m"
      end
      
    end
  end
end
