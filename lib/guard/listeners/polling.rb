module Guard
  class Polling < Listener
    attr_reader :callback, :latency

    def initialize(*)
      super
      @latency = 1.5
    end

    def start
      @stop = false
      super
      watch_change
    end

    def stop
      super
      @stop = true
    end

  private

    def watch_change
      until @stop
        start = Time.now.to_f
        files = modified_files([directory + '/'], :all => true)
        update_last_event
        callback.call(files) unless files.empty?
        nap_time = latency - (Time.now.to_f - start)
        sleep(nap_time) if nap_time > 0
      end
    end

    # we have no real worker here
    # FIXME: cannot watch muliple directories, but is not needed in guard (yet?)
    def watch(directory)
    end

  end
end
