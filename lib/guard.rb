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
    
    def start(options = {})
      @options  = options
      @listener = Listener.init
      @guards   = []
      
      Dsl.evaluate_guardfile
      if guards.empty?
        UI.error "No guards found in Guardfile, please add it at least one."
      else
        Interactor.init_signal_traps
        
        listener.on_change do |files|
          run do
            guards.each do |guard|
              paths = Watcher.match_files(guard, files)
              guard.run_on_change(paths) unless paths.empty?
            end
          end
        end
        
        UI.info "Guard is now watching at '#{Dir.pwd}'"
        guards.each { |g| g.start }
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
    
    def locate_guard(name)
      `gem open guard-#{name} --latest --command echo`
    rescue
      UI.error "Could not find 'guard-#{name}' gem path."
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
    
  end
end