module Guard
  module Report
    CATEGORIES = [:debug, :success, :failure, :info]
    
    class ReportCenter
      attr_reader :ui, :categories
    
      def initialize
        @ui = []
      end
    
      def add_ui(user_interface)
        unless user_interface.respond_to? :report
          raise "#{user_interface} must respond to report(tone, short, options = {})."
        end
        ui.push(user_interface)
      end
    
      def remove_ui(user_interface)
        ui.delete user_interface
      end
      
      def has_category?(type)
        CATEGORIES.include? type
      end
    end
  end
end