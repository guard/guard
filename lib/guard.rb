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
      @listener = Listener.new
      @guards   = []
      
      Dsl.evaluate_guardfile
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
      guards.each(&:start)
      listener.start
    end
    
    def add_guard(name, watchers = [], options = {})
      require "guard/#{name.downcase}"
      guard_class = ObjectSpace.each_object(Class).detect { |c| c.to_s.downcase.match "^guard::#{name.downcase}" }
      @guards << guard_class.new(watchers, options)
    end
    
    def run
      listener.stop
      yield
      listener.start
    end
    
  end
  
end