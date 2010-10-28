require 'bundler'

module Guard
  
  autoload :UI,           'guard/ui'
  autoload :Dsl,          'guard/dsl'
  autoload :Interactor,   'guard/interactor'
  autoload :Listener,     'guard/listener'
  autoload :Watcher,      'guard/watcher'
  autoload :Notifier,     'guard/notifier'
  autoload :ReportCenter, 'guard/report_center'
  
  @guards   = []
  @report_center = ReportCenter.default
  
  
  class << self
    attr_accessor :options, :guards, :listener
    attr_reader :report_center
    
    # initialize this singleton
    def init(options = {})
      @listener = Listener.init
      @options = options
      return self
    end
    
    def start(options = {})
      init options
      
      Dsl.evaluate_guardfile
      if guards.empty?
        UI.error "No guards found in Guardfile, please add at least one."
      else
        Interactor.init_signal_traps
        
        listener.on_change do |files|
          run do
            guards.each do |guard|
              paths = Watcher.match_files(guard, files)
              supervised_task(guard, :run_on_change, paths) unless paths.empty?
            end
          end
        end
        
        ::Guard.info "Guard is now watching at '#{Dir.pwd}'"
        guards.each { |g| supervised_task(g, :start) }
        listener.start
      end
    end
    
    def add_guard(name, watchers = [], options = {})
      guard_class = get_guard_class(name)
      @guards << guard_class.new(watchers, options)
    end
    
    def get_guard_class(name)
      require "guard/#{name.downcase}"
      klasses = []
      ObjectSpace.each_object(Class) do |klass|
        klasses << klass if klass.to_s.downcase.match "^guard::#{name.downcase}"
      end
      klasses.first
    rescue LoadError
      UI.error "Could not find gem 'guard-#{name}' in the current Gemfile."
    end
    
    # Let a guard execute his task but
    # fire it if his work lead to system failure
    def supervised_task(guard, task_to_supervise, *args)
      guard.send(task_to_supervise, *args)
    rescue Exception
      UI.error("#{guard.class.name} guard failed to achieve its <#{task_to_supervise.to_s}> command: #{$!}")
      ::Guard.guards.delete guard
      UI.info("Guard #{guard.class.name} has just been fired")
      return $!
    end
    
    def locate_guard(name)
      `gem open guard-#{name} --latest --command echo`.chomp
    rescue
      UI.error "Could not find 'guard-#{name}' gem path."
    end
    
    def report(type, summary, options = {})
      @report_center.report(type, summary, options)
    end
    
    def run
      listener.stop
      UI.clear if options[:clear]
      begin
        yield
      rescue Interrupt
      end
      listener.start
    end
    
    # Send the message to report if the method_name is one of the valid message type.
    def method_missing(method_name, *args)
      if(ReportCenter::TYPES.include? method_name.to_sym)
        report(method_name, *args)
      else
        super
      end
    end
  end
end