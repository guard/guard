module Guard
  module UI
    
    # this Module is deprecated, it will be removed in version 0.3.0
    # please use the Guard::ReportCenter instead
    class << self
      def info(message, options = {})
        deprecated('info')
        ::Guard.report(:info, message, options)
      end
      
      def error(message)
        deprecated('failure')
        ::Guard.report(:failure, message)
      end
      
      def debug(message)
        deprecated("debug")
        ::Guard.report(:debug, message)
      end
      
      def deprecated(replacement_name=nil)
        if replacement_name.nil?
          puts "DEPRECATED: this method will be removed."
        else
          puts "DEPRECATED: please use ::Guard.#{replacement_name} instead of UI module in Guard plug-ins."
        end
      end
      
      def reset_line
        deprecated
        print "\r\e "
      end
      
      def clear
        deprecated
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
