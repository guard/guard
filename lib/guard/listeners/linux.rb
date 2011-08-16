module Guard
  class Linux < Listener

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
      sleep(@latency)
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
      # The event selection is based on https://github.com/guard/guard/wiki/Analysis-of-inotify-events-for-different-editors
      worker.watch(directory, :recursive, :create, :move_self, :close_write) do |event|
        unless event.name == "" # Event on root directory
          @files << event.absolute_name
        end
      end
    rescue Interrupt
    end

    def watch_change
      @watch_change = true
      until @stop
        if RbConfig::CONFIG['build'] =~ /java/ || IO.select([worker.to_io], [], [], @latency)
          break if @stop

          sleep(@latency)
          worker.process

          files = modified_files(@files.shift(@files.size).map { |f| File.dirname(f) }.uniq)
          @callback.call(files) unless files.empty?
        end
      end
      @watch_change = false
    end

  end
end
