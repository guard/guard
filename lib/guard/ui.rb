module Guard
  module UI
    class << self
      
      def info(message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          clear      if options.key?(:clear) ? options[:clear] : ::Guard.options[:clear]
          puts reset_color(message) if message != ''
        end
      end
      
      def error(message)
        puts "ERROR: #{message}"
      end
      
      def reset_line
        print "\r\e "
      end
      
    private
      
      def clear
        system("clear;")
      end
      
      def reset_color(text)
        color(text, "\e[0m")
      end
      
      def color(text, color_code)
        "#{color_code}#{text}\e[0m"
      end
      
    end
  end
end
