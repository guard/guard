module Guard
  module UI
    
    # this Module is deprecated, it will be removed in version 0.3.0
    # please use the Guard::Report::ReportCenter instead
    class << self
      def info(message, options = {})
        deprecated
        unless ENV["GUARD_ENV"] == "test"
          reset_line if options[:reset]
          puts reset_color(message) if message != ''
        end
      end
      
      def error(message)
        deprecated
        puts "ERROR: #{message}"
      end
      
      def debug(message)
        deprecated
        unless ENV["GUARD_ENV"] == "test"
          puts "DEBUG: #{message}" if ::Guard.options && ::Guard.options[:debug]
        end
      end
      
      def deprecated
        puts "DEPRECATED: please use Guard::Report::ReportCenter instead of UI module in Guard plug-ins."
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
