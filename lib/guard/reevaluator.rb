require "guard"
require "guard/plugin"

module Guard
  class Reevaluator < Guard::Plugin
    def run_on_modifications(files)
      return unless ::Guard::Watcher.match_guardfile?(files)
      ::Guard.save_scope
      ::Guard.evaluator.reevaluate_guardfile
    rescue ScriptError, StandardError => e
      ::Guard::UI.warning("Failed to reevaluate file: #{e}")

      options = { watchers: [::Guard::Watcher.new("Guardfile")] }
      ::Guard.add_plugin(:reevaluator, options)

      throw :task_has_failed
    ensure
      ::Guard.restore_scope
    end
  end
end
