require 'bundler'

module Guard
  
  autoload :UI,         'guard/ui'
  autoload :Dsl,        'guard/dsl'
  autoload :Interactor, 'guard/interactor'
  autoload :Listener,   'guard/listener'
  autoload :Watcher,    'guard/watcher'
  autoload :Notifier,   'guard/notifier'
  
  class << self
    attr_accessor :options, :guards, :listener
    
    # initialize this singleton
    def setup(options = {})
      @options  = options
      @listener = Listener.select_and_init
      @guards   = []
      return self
    end
    
    def start(options = {})
      setup(options)
      
      Interactor.init_signal_traps
      Dsl.evaluate_guardfile
      if guards.empty?
        UI.error "No guards found in Guardfile, please add at least one."
      else
        UI.info "Guard is now watching at '#{Dir.pwd}'"
        guards.each { |g| supervised_task(g, :start) }
        
        Thread.new { listener.start }
        wait_for_changes_and_launch_guards
      end
    end
    
    def wait_for_changes_and_launch_guards
      loop do
        if !running? && !listener.changed_files.empty?
          changed_files = listener.get_and_clear_changed_files
          run do
            guards.each do |guard|
              paths = Watcher.match_files(guard, changed_files)
              supervised_task(guard, :run_on_change, paths) unless paths.empty?
            end
          end
        end
        sleep 0.2
      end
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
    
    def run
      @run = true
      UI.clear if options[:clear]
      begin
        yield
      rescue Interrupt
      end
      @run = false
    end
    
    def running?
      @run == true
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
      UI.error "Could not find gem 'guard-#{name}', please add it in your Gemfile."
    end
    
    def locate_guard(name)
      `gem open guard-#{name} --latest --command echo`.chomp
    rescue
      UI.error "Could not find 'guard-#{name}' gem path."
    end
    
  end
end