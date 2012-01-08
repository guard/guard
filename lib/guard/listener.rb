require 'rbconfig'
require 'digest/sha1'

module Guard

  autoload :Darwin,  'guard/listeners/darwin'
  autoload :Linux,   'guard/listeners/linux'
  autoload :Windows, 'guard/listeners/windows'
  autoload :Polling, 'guard/listeners/polling'

  # The Listener is the base class for all listener
  # implementations.
  #
  # @abstract
  #
  class Listener

    # Default paths that gets ignored by the listener
    DEFAULT_IGNORE_PATHS = %w[. .. .bundle .git log tmp vendor]

    attr_accessor :changed_files
    attr_reader :directory, :ignore_paths

    def paused?
      @paused
    end

    # Select the appropriate listener implementation for the
    # current OS and initializes it.
    #
    # @param [Hash] options the options for the listener
    # @option options [String] watchdir the directory to watch
    # @return [Guard::Listener] the chosen listener
    #
    def self.select_and_init(options = nil)
      watchdir = options && options[:watchdir] && File.expand_path(options[:watchdir])
      watchdir = Dir.pwd unless watchdir

      no_vendor = options && options[:no_vendor] ? options[:no_vendor] : false

      if mac? && Darwin.usable?(no_vendor)
        Darwin.new(watchdir, options)
      elsif linux? && Linux.usable?(no_vendor)
        Linux.new(watchdir, options)
      elsif windows? && Windows.usable?(no_vendor)
        Windows.new(watchdir, options)
      else
        UI.info 'Using polling (Please help us to support your system better than that).'
        Polling.new(watchdir, options)
      end
    end

    # Initialize the listener.
    #
    # @param [String] directory the root directory to listen to
    # @option options [Boolean] relativize_paths use only relative paths
    # @option options [Boolean] watch_all_modifications to enable deleted and moved file listening.
    # @option options [Array<String>] ignore_paths the paths to ignore by the listener
    #
    def initialize(directory = Dir.pwd, options = {})
      @sha1_checksums_hash      = {}
      @file_timestamp_hash      = {}
      @changed_files            = []
      @paused                   = false

      @directory                = directory.to_s

      options                   = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      @relativize_paths         = options.fetch(:relativize_paths, true)
      @watch_all_modifications  = options.fetch(:watch_all_modifications, false)

      @ignore_paths             = DEFAULT_IGNORE_PATHS
      @ignore_paths            |= options[:ignore_paths] if options[:ignore_paths]

      update_last_event
      start_reactor
    end

    # Start the listener thread.
    #
    def start_reactor
      return if ENV["GUARD_ENV"] == 'test'

      Thread.new do
        loop do
          if @changed_files != [] && !@paused
            changed_files = @changed_files.dup
            clear_changed_files
            ::Guard.run_on_change(changed_files)
          else
            sleep 0.1
          end
        end
      end
    end

    # Start watching the root directory.
    #
    def start
      watch(@directory)
      timestamp_files if watch_all_modifications?
    end

    # Stop listening for events.
    #
    def stop
    end

    # Pause the listener to ignore change events.
    #
    def pause
      @paused = true
    end

    # Unpause the listener to listen again to change events.
    #
    def run
      @paused = false
    end

    # Clear the list of changed files.
    #
    def clear_changed_files
      @changed_files.clear
    end

    # Store a listener callback.
    #
    # @param [Block] callback the callback to store
    #
    def on_change(&callback)
      @callback = callback
    end

    # Updates the timestamp of the last event.
    #
    def update_last_event
      @last_event = Time.now
    end

    # Get the modified files.
    #
    # If the `:watch_all_modifications` option is true, then moved and
    # deleted files are also reported, but prefixed by an exclamation point.
    #
    # @example Deleted or moved file
    #   !/home/user/dir/file.rb
    #
    # @param [Array<String>] dirs the watched directories
    # @param [Hash] options the listener options
    # @option options [Symbol] all whether to files in sub directories
    # @return [Array<String>] paths of files that have been modified
    #
    def modified_files(dirs, options = {})
      last_event = @last_event
      files = []

      if watch_all_modifications?
        deleted_files = @file_timestamp_hash.collect do |path, ts|
          unless File.exists?(path)
            @sha1_checksums_hash.delete(path)
            @file_timestamp_hash.delete(path)
            "!#{path}"
          end
        end
        files.concat(deleted_files.compact)
      end
      update_last_event
      updated_files = potentially_modified_files(dirs, options).select do |path|
        file_modified?(path, last_event)
      end
      files.concat(updated_files)

      relativize_paths(files)
    end

    # Register a directory to watch.
    # Must be implemented by the subclasses.
    #
    # @param [String] directory the directory to watch
    #
    def watch(directory)
      raise NotImplementedError, "do whatever you want here, given the directory as only argument"
    end

    # Get all files that are in the watched directory.
    #
    # @return [Array<String>] the list of files
    #
    def all_files
      potentially_modified_files([@directory], :all => true)
    end

    # Scopes all given paths to the current directory.
    #
    # @param [Array<String>] paths the paths to change
    # @return [Array<String>] all paths now relative to the current dir
    #
    def relativize_paths(paths)
      return paths unless relativize_paths?
      paths.map do |path|
        path.gsub(%r{^(!)?#{ @directory }/},'\1')
      end
    end

    # Use paths relative to the current directory.
    #
    # @return [Boolean] whether to use relative or absolute paths
    #
    def relativize_paths?
      !!@relativize_paths
    end

    # test if the listener should also watch for deleted and
    # moved files
    #
    # @return [Boolean] whether to watch all file modifications or not
    #
    def watch_all_modifications?
      !!@watch_all_modifications
    end

    # Populate initial timestamp file hash to watch for deleted or moved files.
    #
    def timestamp_files
      all_files.each { |path| set_file_timestamp_hash(path) }
    end

    # Removes the ignored paths from the directory list.
    #
    # @param [Array<String>] dirs the directory to listen to
    # @param [Array<String>] ignore_paths the paths to ignore
    # @return children of the passed dirs that are not in the ignore_paths list
    #
    def exclude_ignored_paths(dirs, ignore_paths = self.ignore_paths)
      Dir.glob(dirs.map { |d| "#{d.sub(%r{/+$}, '')}/*" }, File::FNM_DOTMATCH).reject do |path|
        ignore_paths.include?(File.basename(path))
      end
    end

    private

    # Gets a list of files that are in the modified directories.
    #
    # @param [Array<String>] dirs the list of directories
    # @param [Hash] options the find file option
    # @option options [Symbol] all whether to files in sub directories
    #
    def potentially_modified_files(dirs, options = {})
      paths = exclude_ignored_paths(dirs)

      if options[:all]
        paths.inject([]) do |array, path|
          if File.file?(path)
            array << path
          else
            array += Dir.glob("#{ path }/**/*", File::FNM_DOTMATCH).select { |p| File.file?(p) }
          end
          array
        end
      else
        paths.select { |path| File.file?(path) }
      end
    end

    # Test if the file content has changed.
    #
    # Depending on the filesystem, mtime/ctime is probably only precise to the second, so round
    # both values down to the second for the comparison.
    #
    # ctime is used only on == comparison to always catches Rails 3.1 Assets pipelined on Mac OSX
    #
    # @param [String] path the file path
    # @param [Time] last_event the time of the last event
    # @return [Boolean] Whether the file content has changed or not.
    #
    def file_modified?(path, last_event)
      ctime = File.ctime(path).to_i
      mtime = File.mtime(path).to_i

      if [mtime, ctime].max == last_event.to_i
        file_content_modified?(path)
      elsif mtime > last_event.to_i
        set_sha1_checksums_hash(path)
        set_file_timestamp_hash(path) if watch_all_modifications?
        true
      elsif watch_all_modifications?
        ts = file_timestamp(path)
        if ts != @file_timestamp_hash[path]
          set_file_timestamp_hash(path, ts)
          true
        end
      else
        false
      end
    rescue
      false
    end

    # Tests if the file content has been modified by
    # comparing the SHA1 checksum.
    #
    # @param [String] path the file path
    #
    def file_content_modified?(path)
      checksum = sha1_checksum(path)
      if @sha1_checksums_hash[path] != checksum
        set_sha1_checksums_hash(path, checksum)
        true
      else
        false
      end
    end

    # Set save a files current timestamp
    #
    # @param [String] path the file path
    # @param [Integer] file_timestamp the files modified timestamp
    #
    def set_file_timestamp_hash(path, timestamp = nil)
      @file_timestamp_hash[path] = timestamp ? timestamp : file_timestamp(path)
    end

    # Set the current checksum of a file.
    #
    # @param [String] path the file path
    # @param [String] sha1_checksum the checksum of the file
    #
    def set_sha1_checksums_hash(path, checksum = nil)
      @sha1_checksums_hash[path] = checksum ? checksum : sha1_checksum(path)
    end

    # Gets a files modified timestamp
    #
    # @param [String] path the file path
    # @return [Integer] file modified timestamp
    #
    def file_timestamp(path)
      File.mtime(path).to_i
    end

    # Calculates the SHA1 checksum of a file.
    #
    # @param [String] path the path to the file
    # @return [String] the SHA1 checksum
    #
    def sha1_checksum(path)
      Digest::SHA1.file(path).to_s
    end

    # Test if the OS is Mac OS X.
    #
    # @return [Boolean] Whether the OS is Mac OS X
    #
    def self.mac?
      RbConfig::CONFIG['target_os'] =~ /darwin/i
    end

    # Test if the OS is Linux.
    #
    # @return [Boolean] Whether the OS is Linux
    #
    def self.linux?
      RbConfig::CONFIG['target_os'] =~ /linux/i
    end

    # Test if the OS is Windows.
    #
    # @return [Boolean] Whether the OS is Windows
    #
    def self.windows?
      RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    end

  end
end
