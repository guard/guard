module Guard
  class Windows < Listener
    attr_reader :fchange

    def initialize
      super
      @fchange = FChange::Notifier.new
    end

    def on_change(&callback)
      @fchange.watch Dir.pwd, :all_events do |event|
        files = modified_files([event.watcher.path])
        update_last_event
        callback.call(files)
      end
    end

    def start
      @fchange.run
    end

    def stop
      @fchange.stop
    end

    def self.usable?
      require 'rb-fchange'
      true
    rescue LoadError
      UI.info "Please install rb-fchange gem for Windows file events support"
      false
    end

  end
end
