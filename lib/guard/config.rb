require "guard/internals/environment"

module Guard
  class Config
    def strict?
      _env.strict?
    end

    def silence_deprecations?
    end

    private

    def _env
      @env ||= _create_env
    end

    def _create_env
      Internals::Environment.new("GUARD").tap do |env|
        env.create_method(:strict?)
      end
    end
  end
end
