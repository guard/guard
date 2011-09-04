module Guard
  class Windows < Listener

    def initialize(*)
      super
      @fchange = FChange::Notifier.new
    end

    def start
      super
      worker.run
    end

    def stop
      super
      worker.stop
    end

    def self.usable?
      require 'rb-fchange'
      true
    rescue LoadError
      UI.info "Please install rb-fchange gem for Windows file events support"
      false
    end

  private

    def worker
      @fchange
    end

    def watch(directory)
      worker.watch(directory, :all_events, :recursive) do |event|
        paths = [File.expand_path(event.watcher.path)]
        files = modified_files(paths, :all => true)
        @callback.call(files) unless files.empty?
      end
    end

  end
end
