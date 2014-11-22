require "guard/plugin"
require "guard/guardfile/evaluator"

module Guard
  class Reevaluator < Plugin
    def run_on_modifications(files)
      # TODO: this is messed up, because reevaluator adds itself
      # anyway, so it know what the path is
      evaluator = Guardfile::Evaluator.new(Guard.options)
      path = evaluator.guardfile_path
      return unless files.any? { |file| File.expand_path(file) == path }

      Guard.save_scope
      evaluator.reevaluate_guardfile
    rescue ScriptError, StandardError => e
      UI.warning("Failed to reevaluate file: #{e}")

      options = { watchers: [::Guard::Watcher.new("Guardfile")] }
      Guard.add_plugin(:reevaluator, options)

      throw :task_has_failed
    ensure
      Guard.restore_scope
    end
  end
end
