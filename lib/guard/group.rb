module Guard

  # A group of Guards.
  #
  class Group

    attr_accessor :name, :options

    # Initialize a Group.
    #
    # @param [String] name the name of the group
    # @param [Hash] options the group options
    # @option options [Boolean] halt_on_fail if a task execution
    #   should be halted for all Guards in this group if one Guard throws `:task_has_failed`
    #
    def initialize(name, options = {})
      @name    = name.to_sym
      @options = options
    end

  end

end
