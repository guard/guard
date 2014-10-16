module Guard
  # The Guard sheller abstract the actual subshell
  # calls and allow easier stubbing.
  #
  class Sheller
    attr_reader :status

    # Creates a new Guard::Sheller object.
    #
    # @param [String] args a command to run in a subshell
    # @param [Array<String>] args an array of command parts to run in a subshell
    # @param [*String] args a list of command parts to run in a subshell
    #
    def initialize(*args)
      fail ArgumentError, "no command given" if args.empty?
      @command = args
      @ran = false
    end

    # Shortcut for new(command).run
    #
    def self.run(*args)
      new(*args).run
    end

    # Shortcut for new(command).run.stdout
    #
    def self.stdout(*args)
      new(*args).stdout
    end

    # Shortcut for new(command).run.stderr
    #
    def self.stderr(*args)
      new(*args).stderr
    end

    # Runs the command.
    #
    # @return [Boolean] whether or not the command succeeded.
    #
    def run
      unless ran?
        status, output, errors = self.class._system(*@command)
        @ran = true
        @stdout = output
        @stderr = errors
        @status = status
      end

      ok?
    end

    # Returns true if the command has already been run, false otherwise.
    #
    # @return [Boolean] whether or not the command has already been run
    #
    def ran?
      @ran
    end

    # Returns true if the command succeeded, false otherwise.
    #
    # @return [Boolean] whether or not the command succeeded
    #
    def ok?
      run unless ran?

      @status.success?
    end

    # Returns the command's output.
    #
    # @return [String] the command output
    #
    def stdout
      run unless ran?

      @stdout
    end

    # Returns the command's error output.
    #
    # @return [String] the command output
    #
    def stderr
      run unless ran?

      @stderr
    end

    # Stubbed by tests
    def self._system(*args)
      out, wout = IO.pipe
      err, werr = IO.pipe

      _result = Kernel.system(*args, err: werr, out: wout)

      [werr, wout].map(&:close)

      output, errors = out.read, err.read
      [out, err].map(&:close)

      [$?.dup, output, errors]
    end
  end
end
