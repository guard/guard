module Guard
  class Linux < Listener
    attr_reader :inotify, :files, :latency

    def initialize(*)
      super

      @inotify = INotify::Notifier.new
      @files   = []
      @latency = 0.5
    end

    def start
      @stop = false
      super
      watch_change unless watch_change?
    end

    def stop
      super
      @stop = true
      sleep latency
    end

    def self.usable?
      require 'rb-inotify'
      if !defined?(INotify::VERSION) || (defined?(Gem::Version) &&
          Gem::Version.new(INotify::VERSION.join('.')) < Gem::Version.new('0.8.5'))
        UI.info "Please update rb-inotify (>= 0.8.5)"
        false
      else
        true
      end
    rescue LoadError
      UI.info "Please install rb-inotify gem for Linux inotify support"
      false
    end

    def watch_change?
      !!@watch_change
    end

  private

    def worker
      @inotify
    end

    def watch(directory)
      worker.watch(directory, :recursive, :modify, :create) do |event|
        unless event.name == "" # Event on root directory
          @files << event.absolute_name
        end
      end
    rescue Interrupt
    end

    def watch_change
      @watch_change = true
      until @stop
        if RbConfig::CONFIG['build'] =~ /java/ || IO.select([inotify.to_io], [], [], latency)
          break if @stop

          sleep latency
          inotify.process
          update_last_event

          unless files.empty?
            files.uniq!
            callback.call( relativate_paths(files) )
            files.clear
          end
        end
      end
      @watch_change = false
    end

  end
end
