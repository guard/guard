require 'sys/uname'

module Guard
  class Listener
    attr_reader :last_event, :callback, :pipe
    
    def initialize
      update_last_event
    end
    
    def on_change(&block)
      @callback = block
    end
    
    def start
      @pipe = case Sys::Uname.sysname
      when 'Darwin'
        IO.popen("#{bin_path}/fsevent_watch .")
      when 'Linux'
        IO.popen("#{bin_path}/inotify_watch .")
      end
      watch_change
    end
    
    def stop
      Process.kill("HUP", pipe.pid) if pipe
    end
    
  private
    
    def watch_change
      while !pipe.eof?
        if line = pipe.readline
          modified_dirs = line.split(" ")
          files = modified_files(modified_dirs)
          update_last_event
          callback.call(files)
        end
      end
    end
    
    def modified_files(dirs)
      files = potentially_modified_files(dirs).select { |file| recent_file?(file) }
      files.map! { |file| file.gsub("#{Dir.pwd}/", '') }
    end
    
    def potentially_modified_files(dirs)
      Dir.glob(dirs.map { |dir| "#{dir}*" })
    end
    
    def recent_file?(file)
      File.mtime(file) >= last_event
    end
    
    def update_last_event
      @last_event = Time.now
    end
    
    def bin_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin'))
    end
    
  end
end