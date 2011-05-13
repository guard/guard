require 'rbconfig'

module Guard

  autoload :Darwin,  'guard/listeners/darwin'
  autoload :Linux,   'guard/listeners/linux'
  autoload :Windows, 'guard/listeners/windows'
  autoload :Polling, 'guard/listeners/polling'

  class Listener
    attr_reader :last_event, :sha1_checksums_hash, :directory

    def self.select_and_init
      if mac? && Darwin.usable?
        Darwin.new
      elsif linux? && Linux.usable?
        Linux.new
      elsif windows? && Windows.usable?
        Windows.new
      else
        UI.info "Using polling (Please help us to support your system better than that.)"
        Polling.new
      end
    end

    def initialize(directory=Dir.pwd)
      @directory = directory.to_s
      @sha1_checksums_hash = {}
      update_last_event
    end

    def start
      watch directory
    end

    def stop
    end

    def on_change(&callback)
      @callback = callback
    end

    def update_last_event
      @last_event = Time.now
    end

    def modified_files(dirs, options = {})
      files = potentially_modified_files(dirs, options).select { |path| File.file?(path) && file_modified?(path) && file_content_modified?(path) }
      files.map! { |file| file.gsub("#{directory}/", '') }
    end

    def worker
      raise NotImplementedError, "should respond to #watch"
    end

    # register a directory to watch. must be implemented by the subclasses
    def watch(directory)
      raise NotImplementedError, "do whatever you want here, given the directory as only argument"
    end

  private

    def potentially_modified_files(dirs, options = {})
      match = options[:all] ? "**/*" : "*"
      Dir.glob(dirs.map { |dir| "#{dir}#{match}" })
    end

    def file_modified?(path)
      # Depending on the filesystem, mtime is probably only precise to the second, so round
      # both values down to the second for the comparison.
      File.mtime(path).to_i >= last_event.to_i
    rescue
      false
    end

    def file_content_modified?(path)
      sha1_checksum = Digest::SHA1.file(path).to_s
      if sha1_checksums_hash[path] != sha1_checksum
        @sha1_checksums_hash[path] = sha1_checksum
        true
      else
        false
      end
    end

    def self.mac?
      Config::CONFIG['target_os'] =~ /darwin/i
    end

    def self.linux?
      Config::CONFIG['target_os'] =~ /linux/i
    end

    def self.windows?
      Config::CONFIG['target_os'] =~ /mswin|mingw/i
    end

  end
end
