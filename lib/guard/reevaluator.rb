require "guard"
require "guard/plugin"

module Guard
  class Reevaluator < Guard::Plugin
    def run_on_modifications(files)
      return unless ::Guard::Watcher.match_guardfile?(files)
      ::Guard.save_scope
      ::Guard.evaluator.reevaluate_guardfile
      ::Guard.restore_scope
    end
  end
end
