module Guard
  module Commands
    module WithEngine
      attr_reader :engine

      def import(engine:)
        @engine = engine
      end
    end
  end
end
