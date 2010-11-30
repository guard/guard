module Guard
  class Linux < Listener
    attr_reader :inotify
    
    def initialize
      super
      @inotify = INotify::Notifier.new
      inotify.watch(Dir.pwd, :recursive, :modify, :create, :delete, :move) do |event|
        unless event.name == "" # Event on root directory
          @changed_files << event.absolute_name.gsub("#{Dir.pwd}/", '')
        end
      end
    end
    
    def start
      inotify.run
    end
    
    def stop
      inotify.stop
    end
    
    def self.usable?
      require 'rb-inotify'
      if !defined?(INotify::VERSION) || Gem::Version.new(INotify::VERSION.join('.')) < Gem::Version.new('0.5.1')
        UI.info "Please update rb-inotify (>= 0.5.1)"
        false
      else
        true
      end
    rescue LoadError
      UI.info "Please install rb-inotify gem for Linux inotify support"
      false
    end
    
  end
end