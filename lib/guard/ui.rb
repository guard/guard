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
        print "\r\e[0m"
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
