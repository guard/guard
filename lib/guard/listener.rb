require 'rbconfig'

module Guard

  autoload :Darwin,  'guard/listeners/darwin'
  autoload :Linux,   'guard/listeners/linux'
  autoload :Polling, 'guard/listeners/polling'

  class Listener
    attr_reader :last_event

    def self.select_and_init
      if mac? && Darwin.usable?
        Darwin.new
      elsif linux? && Linux.usable?
        Linux.new
      else
        UI.info "Using polling (Please help us to support your system better than that.)"
        Polling.new
      end
    end

    def initialize
      update_last_event
    end

    def update_last_event
      @last_event = Time.now
    end

    def modified_files(dirs, options = {})
      files = potentially_modified_files(dirs, options).select { |path| File.file?(path) && recent_file?(path) }
      files.map! { |file| file.gsub("#{Dir.pwd}/", '') }
    end

  private

    def potentially_modified_files(dirs, options = {})
      match = options[:all] ? "**/*" : "*"
      Dir.glob(dirs.map { |dir| "#{dir}#{match}" })
    end

    def recent_file?(file)
      File.mtime(file) >= last_event
    rescue
      false
    end

    def self.mac?
      Config::CONFIG['target_os'] =~ /darwin/i
    end

    def self.linux?
      Config::CONFIG['target_os'] =~ /linux/i
    end

  end
end

# require 'rbconfig'
#
# module Guard
#
#   autoload :Darwin,  'guard/listeners/darwin'
#   autoload :Linux,   'guard/listeners/linux'
#   autoload :Polling, 'guard/listeners/polling'
#
#   class Listener
#     attr_accessor :last_event, :changed_files
#
#     def self.select_and_init
#       if mac? && Darwin.usable?
#         Darwin.new
#       elsif linux? && Linux.usable?
#         Linux.new
#       else
#         UI.info "Using polling (Please help us to support your system better than that.)"
#         Polling.new
#       end
#     end
#
#     def initialize
#       @changed_files = []
#       update_last_event
#     end
#
#     def get_and_clear_changed_files
#       files = changed_files.dup
#       changed_files.clear
#       files.uniq
#     end
#
#   private
#
#     def find_changed_files(dirs, options = {})
#       files = potentially_changed_files(dirs, options).select { |path| File.file?(path) && changed_file?(path) }
#       files.map! { |file| file.gsub("#{Dir.pwd}/", '') }
#     end
#
#     def potentially_changed_files(dirs, options = {})
#       match = options[:all] ? "**/*" : "*"
#       Dir.glob(dirs.map { |dir| "#{dir}#{match}" })
#     end
#
#     def changed_file?(file)
#       File.mtime(file) >= last_event
#     rescue
#       false
#     end
#
#     def update_last_event
#       @last_event = Time.now
#     end
#
#     def self.mac?
#       Config::CONFIG['target_os'] =~ /darwin/i
#     end
#
#     def self.linux?
#       Config::CONFIG['target_os'] =~ /linux/i
#     end
#
#   end
# end