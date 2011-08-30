module Guard

  autoload :UI,           'guard/ui'
  autoload :Dsl,          'guard/dsl'
  autoload :DslDescriber, 'guard/dsl_describer'
  autoload :Interactor,   'guard/interactor'
  autoload :Listener,     'guard/listener'
  autoload :Watcher,      'guard/watcher'
  autoload :Notifier,     'guard/notifier'

  class << self
    attr_accessor :options, :guards, :interactor, :listener

    # initialize this singleton
    def setup(options = {})
      @options    = options
      @guards     = []
      @interactor = Interactor.new
      @listener   = Listener.select_and_init(@options[:watchdir] ? File.expand_path(@options[:watchdir]) : Dir.pwd)

      @options[:notify] && ENV["GUARD_NOTIFY"] != 'false' ? Notifier.turn_on : Notifier.turn_off

      UI.clear if @options[:clear]
      debug_command_execution if @options[:debug]

      self
    end

    def start(options = {})
      setup(options)

      Dsl.evaluate_guardfile(options)

      UI.info "Guard is now watching at '#{listener.directory}'"
      guards.each { |guard| supervised_task(guard, :start) }

      interactor.start
      listener.start
    end

    def stop
      UI.info "Bye bye...", :reset => true
      listener.stop
      guards.each { |guard| supervised_task(guard, :stop) }
      abort
    end

    def reload
      run do
        guards.each { |guard| supervised_task(guard, :reload) }
      end
    end

    def run_all
      run do
        guards.each { |guard| supervised_task(guard, :run_all) }
      end
    end

    def pause
      if listener.locked
        UI.info "Un-paused files modification listening", :reset => true
        listener.clear_changed_files
        listener.unlock
      else
        UI.info "Paused files modification listening", :reset => true
        listener.lock
      end
    end

    def run_on_change(files)
      run do
        guards.each do |guard|
          paths = Watcher.match_files(guard, files)
          unless paths.empty?
            UI.debug "#{guard.class.name}#run_on_change with #{paths.inspect}"
            supervised_task(guard, :run_on_change, paths)
          end
        end
      end
    end

    def run
      listener.lock
      interactor.lock
      UI.clear if options[:clear]
      begin
        yield
      rescue Interrupt
      end
      interactor.unlock
      listener.unlock
    end

    # Let a guard execute its task but
    # fire it if his work leads to a system failure
    def supervised_task(guard, task_to_supervise, *args)
      guard.send(task_to_supervise, *args)
    rescue Exception => ex
      UI.error("#{guard.class.name} failed to achieve its <#{task_to_supervise.to_s}>, exception was:" +
      "\n#{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}")
      guards.delete guard
      UI.info("\n#{guard.class.name} has just been fired")
      return ex
    end

    def add_guard(name, watchers = [], options = {})
      if name.downcase == 'ego'
        UI.deprecation("Guard::Ego is now part of Guard. You can remove it from your Guardfile.")
      else
        guard_class = get_guard_class(name)
        @guards << guard_class.new(watchers, options)
      end
    end

    def get_guard_class(name)
      try_require = false
      const_name = name.to_s.downcase.gsub('-', '')
      begin
        require "guard/#{name.to_s.downcase}" if try_require
        self.const_get(self.constants.find {|c| c.to_s.downcase == const_name })
      rescue TypeError
        unless try_require
          try_require = true
          retry
        else
          UI.error "Could not find class Guard::#{const_name.capitalize}"
        end
      rescue LoadError => loadError
        UI.error "Could not load 'guard/#{name.downcase}' or find class Guard::#{const_name.capitalize}"
        UI.error loadError.to_s
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

    ##
    # Returns a list of guard Gem names installed locally.
    def guard_gem_names
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_all.select { |x| x.name =~ /^guard-/ }
      else
        Gem.source_index.find_name(/^guard-/)
      end.map { |x| x.name.sub /^guard-/, '' }
    end

    def debug_command_execution
      Kernel.send(:alias_method, :original_system, :system)
      Kernel.send(:define_method, :system) do |command, *args|
        ::Guard::UI.debug "Command execution: #{command} #{args.join(' ')}"
        original_system command, *args
      end

      Kernel.send(:alias_method, :original_backtick, :"`")
      Kernel.send(:define_method, :"`") do |command|
        ::Guard::UI.debug "Command execution: #{command}"
        original_backtick command
      end
    end

  end
end
