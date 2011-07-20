require 'rbconfig'
require 'digest/sha1'

module Guard

  autoload :Darwin,  'guard/listeners/darwin'
  autoload :Linux,   'guard/listeners/linux'
  autoload :Windows, 'guard/listeners/windows'
  autoload :Polling, 'guard/listeners/polling'

  class Listener
    attr_reader :last_event, :sha1_checksums_hash, :directory, :callback

    def self.select_and_init(*a)
      if mac? && Darwin.usable?
        Darwin.new(*a)
      elsif linux? && Linux.usable?
        Linux.new(*a)
      elsif windows? && Windows.usable?
        Windows.new(*a)
      else
        UI.info "Using polling (Please help us to support your system better than that.)"
        Polling.new(*a)
      end
    end

    def initialize(directory=Dir.pwd, options={})
      @directory = directory.to_s
      @sha1_checksums_hash = {}
      @relativate_paths = options.fetch(:relativate_paths, true)
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

    def modified_files(dirs, options={})
      files = potentially_modified_files(dirs, options).select { |path| file_modified?(path) }
      update_last_event
      relativize_paths(files)
    end

    def worker
      raise NotImplementedError, "should respond to #watch"
    end

    # register a directory to watch. must be implemented by the subclasses
    def watch(directory)
      raise NotImplementedError, "do whatever you want here, given the directory as only argument"
    end

    def all_files
      potentially_modified_files [directory + '/'], :all => true
    end

    # scopes all given paths to the current #directory
    def relativate_paths(paths)
      return paths unless relativate_paths?
      paths.map do |path|
        path.gsub(%r~^#{directory}/~, '')
      end
    end

    attr_writer :relativate_paths
    def relativate_paths?
      !!@relativate_paths
    end

  private

    def potentially_modified_files(dirs, options = {})
      match = options[:all] ? "**/*" : "*"
      Dir.glob(dirs.map { |dir| "#{dir}#{match}" }, File::FNM_DOTMATCH).select { |file| File.file?(file) }
    end

    # Depending on the filesystem, mtime is probably only precise to the second, so round
    # both values down to the second for the comparison.
    def file_modified?(path)
      if File.mtime(path).to_i == last_event.to_i
        file_content_modified?(path, sha1_checksum(path))
      elsif File.mtime(path).to_i > last_event.to_i
        set_sha1_checksums_hash(path, sha1_checksum(path))
        true
      end
    rescue
      false
    end

    def file_content_modified?(path, sha1_checksum)
      if sha1_checksums_hash[path] != sha1_checksum
        set_sha1_checksums_hash(path, sha1_checksum)
        true
      else
        false
      end
    end

    def set_sha1_checksums_hash(path, sha1_checksum)
      @sha1_checksums_hash[path] = sha1_checksum
    end

    def sha1_checksum(path)
      Digest::SHA1.file(path).to_s
    end

    def self.mac?
      RbConfig::CONFIG['target_os'] =~ /darwin/i
    end

    def self.linux?
      RbConfig::CONFIG['target_os'] =~ /linux/i
    end

    def self.windows?
      RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    end

  end
end
