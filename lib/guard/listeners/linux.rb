module Guard
  class Linux < Listener
    attr_reader :inotify, :files, :latency, :callback

    def initialize
      super

      @inotify = INotify::Notifier.new
      @files   = []
      @latency = 0.5
    end

    def start
      @stop = false
      watch_change unless watch_change?
    end

    def stop
      @stop = true
      sleep latency
    end

    def on_change(&callback)
      @callback = callback
      inotify.watch(Dir.pwd, :recursive, :modify, :create, :delete, :move) do |event|
        unless event.name == "" # Event on root directory
          @files << event.absolute_name
        end
      end
    rescue Interrupt
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

    def watch_change?
      !!@watch_change
    end

  private

    def watch_change
      @watch_change = true
      while !@stop
        if Config::CONFIG['build'] =~ /java/ || IO.select([inotify.to_io], [], [], latency)
          break if @stop

          sleep latency
          inotify.process
          update_last_event

          unless files.empty?
            files.uniq!
            files.map! { |file| file.gsub("#{Dir.pwd}/", '') }
            callback.call(files)
            files.clear
          end
        end
      end
      @watch_change = false
    end

  end
end
