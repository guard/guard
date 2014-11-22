require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

require "guard/ui"

module Guard
  module Deprecated
    module Evaluator
      def self.add_deprecated(klass)
        klass.send(:include, self)
      end

      EVALUATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
        Starting with Guard 2.8.3 'Guard::Evaluator#evaluate_guardfile' is
        deprecated in favor of '#evaluate'.
      EOS

      REEVALUATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
        Starting with Guard 2.8.3 'Guard::Evaluator#reevaluate_guardfile' is
        deprecated in favor of '#reevaluate'.
      EOS

      def evaluate_guardfile
        UI.deprecation(EVALUATE_GUARDFILE)
        evaluate
      end

      def reevaluate_guardfile
        UI.deprecation(REEVALUATE_GUARDFILE)
        ::Guard::Reevaluator.new.reevaluate
      end
    end
  end
end
