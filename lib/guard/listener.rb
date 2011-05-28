require 'rbconfig'
require 'digest/sha1'

module Guard

  autoload :Darwin,  'guard/listeners/darwin'
  autoload :Linux,   'guard/listeners/linux'
  autoload :Windows, 'guard/listeners/windows'
  autoload :Polling, 'guard/listeners/polling'

  class Listener
    attr_reader :last_event, :sha1_checksums_hash

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

    def initialize
      @sha1_checksums_hash = {}
      update_last_event
    end

    def update_last_event
      @last_event = Time.now
    end

    def modified_files(dirs, options = {})
      files = potentially_modified_files(dirs, options).select { |path| File.file?(path) && file_modified?(path) }
      files.map! { |file| file.gsub("#{Dir.pwd}/", '') }
    end

  private

    def potentially_modified_files(dirs, options = {})
      match = options[:all] ? "**/*" : "*"
      Dir.glob(dirs.map { |dir| "#{dir}#{match}" })
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
      ::Digest::SHA1.file(path).to_s
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
