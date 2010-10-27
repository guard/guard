module Guard
  module Report
    
    VALID_TONE = [:positive, :negative, :neutral]
    
    class Category
      
      attr_reader :tone, :type, :name, :verbosity
      
      def initialize(tone)
        @tone = tone
        @type = tone
        @name = tone.to_s[0..0].upcase + tone.to_s[1..-1]
        @verbosity = 5
      end
    end
  end
end