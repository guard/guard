module Guard  
  require 'guard/ui/console'
  require 'guard/ui/notifier'
  
  class ReportCenter
    attr_reader :ui, :categories
    
    @@default_instance = nil
    
    TYPES = [:debug, :success, :failure, :info]
    VALID_REPORT_OPTIONS = [:detail]
    VALID_UI_OPTIONS = [:subscribe_to]
    
    def self.default
      if(@@default_instance.nil?)
        @@default_instance = ReportCenter.new
        @@default_instance.add_ui(UI::Console.new, :subscribe_to => :all)
        @@default_instance.add_ui(UI::Notifier.new)
      end
      @@default_instance
    end
  
    def initialize
      @ui = []
      @subscriptions = {}
      TYPES.each {|t| @subscriptions[t] = []}
    end
    
    # Send a report to all concerned UI
    def report(type, summary, options = {})
      # The exception will get up to the guilty guard plug-in, 
      # so the supervised task will failed and the guard will be
      # fired for this wrong message.
      if(summary.nil? || summary.to_s.empty?)
        raise "Invalid report: summary is mandatory"
      end
      unless(TYPES.include? type)
        raise "Invalid report: type must be one of #{TYPES.inspect} but is #{type}."
      end
      options.each do |key, value|
        unless VALID_REPORT_OPTIONS.include? key
          raise "Invalid report: options only accepts #{VALID_REPORT_OPTIONS.inspect}, received #{key.inspect}"
        end
      end
      
      @subscriptions[type].each {|ui| ui.report type, summary, options}
    end
  
    def add_ui(user_interface, options = {})
      unless user_interface.respond_to? :report
        raise "#{user_interface} must respond to report(type, summary, options = {})."
      end
      options.each do |key, value|
        unless VALID_UI_OPTIONS.include? key
          raise "Illegal argument: options only accepts #{VALID_UI_OPTIONS.inspect}, received #{key.inspect}"
        end
      end
      
      subscribed_types = [:success, :failure, :info]
      if(options[:subscribe_to] == :all)
        subscribed_types = TYPES
      elsif options[:subscribe_to].kind_of? Array
        subscribed_types = options[:subscribe_to]
      elsif options[:subscribe_to].kind_of? Symbol
        subscribed_types = [options[:subscribe_to]]
      elsif options.include? :subscribe_to
        raise "Illegal argument: :subscribe_to option must be either :all, a symbol or an array of symbol"
      end
      subscribed_types.each {|t| @subscriptions[t].push user_interface unless @subscriptions[t].include? user_interface}          
      ui.push(user_interface)
    end
  
    def remove_ui(user_interface)
      ui.delete user_interface
      @subscriptions.each {|t, subscribers| subscribers.delete user_interface}
    end
    
    def has_category?(type)
      TYPES.include? type
    end
  end
end