module Guard
  class Polling < Listener
    attr_reader :callback, :latency, :existing

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
        current = all_files
        changed = []
        # removed files
        changed += existing - current
        # added files
        changed += current - existing
        # modified
        changed += existing.select { |path| File.file?(path) && file_modified?(path) && file_content_modified?(path) }
        update_last_event

        changed.uniq!

        callback.call( relativate_paths(changed) ) unless changed.empty?
        @existing = current
        nap_time = latency - (Time.now.to_f - start)
        sleep(nap_time) if nap_time > 0
      end
    end

    # FIXME: cannot watch muliple directories, but is not needed in guard (yet?)
    def watch(directory)
      @existing = all_files
    end

  end
end
