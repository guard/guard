module Guard

  # A group of Guards. There are two reasons why you want to group your guards:
  #
  # - You can start only certain Groups from the command line by passing the `--group` option.
  # - Abort task execution chain on failure within a group.
  #
  # @example Group that aborts on failure
  #
  #   group :frontend, :halt_on_fail => true do
  #     guard 'coffeescript', :input => 'spec/coffeescripts', :output => 'spec/javascripts'
  #     guard 'jasmine-headless-webkit' do
  #       watch(%r{^spec/javascripts/(.*)\..*}) { |m| newest_js_file("spec/javascripts/#{m[1]}_spec") }
  #     end
  #   end
  #
  # @see Guard::CLI
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
