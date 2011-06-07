module Guard

  autoload :UI,         'guard/ui'
  autoload :Dsl,        'guard/dsl'
  autoload :Interactor, 'guard/interactor'
  autoload :Listener,   'guard/listener'
  autoload :Watcher,    'guard/watcher'
  autoload :Notifier,   'guard/notifier'

  class << self
    attr_accessor :options, :guards, :listener

    # initialize this singleton
    def setup(options = {})
      @options  = options
      @listener = Listener.select_and_init
      @guards   = []

      @options[:notify] && ENV["GUARD_NOTIFY"] != 'false' ? Notifier.turn_on : Notifier.turn_off

      self
    end

    def start(options = {})
      setup(options)

      Interactor.init_signal_traps
      Dsl.evaluate_guardfile(options)

      if guards.empty?
        UI.error "No guards found in Guardfile, please add at least one."
      else
        listener.on_change do |files|
          run { run_on_change_for_all_guards(files) } if Watcher.match_files?(guards, files)
        end

        UI.info "Guard is now watching at '#{Dir.pwd}'"
        guards.each { |guard| supervised_task(guard, :start) }
        listener.start
      end
    end

    def run_on_change_for_all_guards(files)
      guards.each do |guard|
        paths = Watcher.match_files(guard, files)
        supervised_task(guard, :run_on_change, paths) unless paths.empty?
      end

      # Reparse the whole directory to catch new files modified during the guards run
      new_modified_files = listener.modified_files([Dir.pwd + '/'], :all => true)
      listener.update_last_event
      if !new_modified_files.empty? && Watcher.match_files?(guards, new_modified_files)
        run { run_on_change_for_all_guards(new_modified_files) }
      end
    end

    # Let a guard execute its task but
    # fire it if his work leads to a system failure
    def supervised_task(guard, task_to_supervise, *args)
      guard.send(task_to_supervise, *args)
    rescue Exception
      UI.error("#{guard.class.name} guard failed to achieve its <#{task_to_supervise.to_s}> command: #{$!}")
      guards.delete guard
      UI.info("Guard #{guard.class.name} has just been fired")
      return $!
    end

    def run
      listener.stop
      UI.clear if options[:clear]
      begin
        yield
      rescue Interrupt
      end
      listener.start
    end

    def add_guard(name, watchers = [], options = {})
      guard_class = get_guard_class(name)
      @guards << guard_class.new(watchers, options)
    end

    def get_guard_class(name)
      try_require = false
      const_name = name.to_s.downcase.gsub('-', '')
      begin
        require "guard/#{name.downcase}" if try_require
        self.const_get(self.constants.find {|c| c.to_s.downcase == const_name })
      rescue TypeError
        unless try_require
          try_require = true
          retry
        else
          UI.error "Could not find class Guard::#{const_name.capitalize}"
        end
      rescue LoadError
        UI.error "Could not load 'guard/#{name.downcase}' or find class Guard::#{const_name.capitalize}"
      end
    end

    def locate_guard(name)
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_by_name("guard-#{name}").full_gem_path
      else
        Gem.source_index.find_name("guard-#{name}").last.full_gem_path
      end
    rescue
      UI.error "Could not find 'guard-#{name}' gem path."
    end

  end
end
