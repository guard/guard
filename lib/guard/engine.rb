require "guard/internals/helpers"
require "guard/commander"

module Guard
  class Engine
    include Commander
    include Internals::Helpers

    attr_reader :state, :queue, :interactor, :listener

    def initialize(cmdline_opts:)
      @state = Internals::State.new(engine: self, cmdline_opts: cmdline_opts)
      @queue = Internals::Queue.new(engine: self)
      @interactor = Interactor.new(engine: self)

      # NOTE: this should be *after* evaluate so :directories can work
      # TODO: move listener setup to session?
      @listener = Listen.send(*session.listener_args, &_listener_callback)

      ignores = session.guardfile_ignore
      @listener.ignore(ignores) unless ignores.empty?

      ignores = session.guardfile_ignore_bang
      @listener.ignore!(ignores) unless ignores.empty?
    end

    def inspect
      "#<#{self.class} @plugins=#{plugins.all.map(&:title)} @groups=#{groups.all.map(&:title)}>"
    end

    def session
      state.session
    end

    def scope
      state.scope
    end

    def plugins
      session.plugins
    end

    def groups
      session.groups
    end

    def evaluate_guardfile
      _evaluate
    end

    # Asynchronously trigger changes
    #
    # Currently supported args:
    #
    #   @example Old style hash:
    #     async_queue_add(modified: ['foo'], added: ['bar'], removed: [])
    #
    #   @example New style signals with args:
    #     async_queue_add([:guard_pause, :unpaused ])
    #
    def async_queue_add(changes)
      @queue << changes

      # Putting interactor in background puts guard into foreground
      # so it can handle change notifications
      Thread.new { @interactor.background }
    end

    private

    def _listener_callback
      lambda do |modified, added, removed|
        relative_paths = {
          modified: _relative_pathnames(modified),
          added: _relative_pathnames(added),
          removed: _relative_pathnames(removed)
        }

        _guardfile_deprecated_check(relative_paths[:modified])

        async_queue_add(relative_paths) if _relevant_changes?(relative_paths)
      end
    end

    def _evaluate
      evaluator = Guardfile::Evaluator.new(engine: self)
      evaluator.evaluate

      UI.reset_and_clear(engine: self)

      msg = "No plugins found in Guardfile, please add at least one."
      UI.error msg if _pluginless_guardfile?

      if evaluator.inline?
        UI.info("Using inline Guardfile.")
      elsif evaluator.custom?
        UI.info("Using Guardfile at #{ evaluator.path }.")
      end
    rescue Guardfile::Evaluator::NoPluginsError => e
      UI.error(e.message)
    end

    def _relative_pathnames(paths)
      paths.map { |path| _relative_pathname(path) }
    end

    # TODO: remove at some point
    # TODO: not tested because collides with ongoing refactoring
    def _guardfile_deprecated_check(modified)
      modified.map!(&:to_s)
      regexp = %r{^(?:.+/)?Guardfile$}
      guardfiles = modified.select { |path| regexp.match(path) }
      return if guardfiles.empty?

      guardfile = Pathname("Guardfile").realpath
      real_guardfiles = guardfiles.detect do |path|
        /^Guardfile$/.match(path) || Pathname(path).expand_path == guardfile
      end

      return unless real_guardfiles

      UI.warning "Guardfile changed -- _guard-core will exit.\n"
      exit 2 # nonzero to break any while loop
    end

    # Check if any of the changes are actually watched for
    # TODO: why iterate twice? reuse this info when running tasks
    def _relevant_changes?(changes)
      # TODO: no coverage!
      files = changes.values.flatten(1)
      watchers = scope.grouped_plugins.map do |_group, plugins|
        plugins.map(&:watchers).flatten
      end.flatten
      watchers.any? { |watcher| files.any? { |file| watcher.match(file) } }
    end

    # TODO: obsoleted? (move to Dsl?)
    def _pluginless_guardfile?
      session.plugins.all.empty?
    end
  end
end
