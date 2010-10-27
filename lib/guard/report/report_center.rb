module Guard
  module Report
    autoload :Category,  'guard/report/category'
    
    class ReportCenter
      attr_reader :ui, :categories
    
      def initialize
        @ui = []
        @categories = {}
        add_category(Category.new(:neutral))
        add_category(Category.new(:positive))
        add_category(Category.new(:negative))
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
    
      # Add the category after ensuring it did not already exists
      def add_category(message_category)
        unless VALID_TONE.include? message_category.tone
          raise "#{message_category} tone must be one of #{VALID_TONE.inspect}"
        end
        if has_category?(message_category.type)
          if get_category(message_category.type).tone != message_category.tone
            raise "category of type #{message_category.type} is already " + 
              "registered with a tone of #{get_category(message_category.type).tone}"
          end
        else
          categories[message_category.type] = message_category
        end
      end
      
      def get_category(type)
        categories[type]
      end
      
      def has_category?(type)
        categories.include? type
      end
    end
  end
end