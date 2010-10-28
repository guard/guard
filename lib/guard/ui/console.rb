module Guard
  module UI
    class Console
      def report(type, message, options = {})
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
        end
        if(options.include? :detail)
          message = "#{message}\n\n#{detail}"
        end
        send(type, message)
      end
      
    protected
      def success(message)
        puts "SUCCESS: #{message}"
      end
    
      def info(message)
        puts "INFO: #{message}"
      end
      
      def failure(message)
        puts "FAILURE: #{message}"
      end
      
      def debug(message)
        unless ENV["GUARD_ENV"] == "test"
          puts "DEBUG: #{message}"
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
