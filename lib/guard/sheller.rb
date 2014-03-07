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
      @command = args.join(' ')
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

    # Runs the command.
    #
    # @return [Boolean] whether or not the command succeeded.
    #
    def run
      unless run?
        @stdout = `#{@command}`
        @status = $?
      end

      success?
    end

    # Returns true if the command has already been run, false otherwise.
    #
    # @return [Boolean] whether or not the command has already been run
    #
    def run?
      !@status.nil?
    end

    # Returns true if the command succeeded, false otherwise.
    #
    # @return [Boolean] whether or not the command succeeded
    #
    def success?
      run unless run?

      @status.success?
    end

    # Returns the command's output.
    #
    # @return [String] the command output
    #
    def stdout
      run unless run?

      @stdout
    end

  end
end

