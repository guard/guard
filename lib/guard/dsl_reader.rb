# frozen_string_literal: true

module Guard
  # @private
  class DslReader
    Error = Class.new(RuntimeError)

    attr_reader :engine, :plugin_names

    def initialize(engine)
      @engine = engine
      @plugin_names = []
    end

    def evaluate(contents, filename, lineno)
      instance_eval(contents, filename.to_s, lineno)
    rescue StandardError, ScriptError => e
      prefix = "\n\t(dsl)> "
      cleaned_backtrace = self.class.cleanup_backtrace(e.backtrace)
      backtrace = "#{prefix}#{cleaned_backtrace.join(prefix)}"
      msg = "Invalid Guardfile, original error is: \n\n%s, \nbacktrace: %s"
      raise Error, format(msg, e, backtrace)
    end

    def guard(name, _options = {})
      @plugin_names << name.to_s
    end

    # Stub everything else
    def notification(_notifier, _opts = {}); end

    def interactor(_options); end

    def group(*_args); end

    def watch(_pattern, &_action); end

    def callback(*_args, &_block); end

    def ignore(*_regexps); end

    def ignore!(*_regexps); end

    def logger(_options); end

    def scope(_scope = {}); end

    def directories(_directories); end

    def clearing(_on); end

    def self.cleanup_backtrace(backtrace)
      dirs = { File.realpath(Dir.pwd) => ".", }

      gem_env = ENV["GEM_HOME"] || ""
      dirs[gem_env] = "$GEM_HOME" unless gem_env.empty?

      gem_paths = (ENV["GEM_PATH"] || "").split(File::PATH_SEPARATOR)
      gem_paths.each_with_index do |path, index|
        dirs[path] = "$GEM_PATH[#{index}]"
      end

      backtrace.dup.map do |raw_line|
        path = nil
        symlinked_path = raw_line.split(":").first
        begin
          path = raw_line.sub(symlinked_path, File.realpath(symlinked_path))
          dirs.detect { |dir, name| path.sub!(File.realpath(dir), name) }
          path
        rescue Errno::ENOENT
          path || symlinked_path
        end
      end
    end
  end
end
