require 'ostruct'

module Guard

  # A class that holds options. Can be instantiated with default options.
  #
  class Options < OpenStruct

    attr_accessor :options

    # Initializes an Guard::Options object. `default_opts` is merged into
    # `opts`.
    #
    # @param [Hash] opts the options
    # @param [Hash] default_opts the default options
    #
    def initialize(opts = {}, default_opts = {})
      opts = default_opts.dup.merge(opts.dup)

      super(opts)
    end

  end

end
