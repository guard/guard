module Guard
  class Polling < Listener
    attr_reader :callback, :latency
    
    def initialize
      super
      @latency = 1.5
    end
    
    def start
      @stop = false
      watch_change
    end
    
    def stop
      @stop = true
    end
    
  private
    
    def watch_change
      while !@stop
        start = Time.now.to_f
        if files = find_changed_files([Dir.pwd + '/'], :all => true)
          update_last_event
          @changed_files += files
        end
        nap_time = latency - (Time.now.to_f - start)
        sleep(nap_time) if nap_time > 0
      end
    end
    
  end
end