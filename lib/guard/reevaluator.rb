require "guard/plugin"
require "guard/guardfile/evaluator"
require "guard/runner"
require "guard/internals/helpers"

module Guard
  class Reevaluator < Plugin
    include Internals::Helpers
    def run_on_modifications(files)
      # TODO: this is messed up, because reevaluator adds itself
      # anyway, so it know what the path is
      evaluator = _evaluator
      path = evaluator.path
      return unless files.any? { |file| path == Pathname(file) }
      reevaluate
    rescue Dsl::Error, Guardfile::Evaluator::Error => e
      UI.warning("Failed to reevaluate file: #{e}")
      _add_self_to_plugins
      throw :task_has_failed
    end

    def reevaluate
      evaluator = _evaluator
      return if evaluator.inline?

      Runner.new.run(:stop)

      Guard.save_scope
      Guard.reset_groups
      Guard.reset_plugins
      Guard.reset_scope

      Notifier.disconnect
      evaluator.evaluate
      Notifier.connect(Guard.options)

      if Guard.send(:_pluginless_guardfile?)
        Notifier.notify(
          "No plugins found in Guardfile, please add at least one.",
          title: "Guard re-evaluate",
          image: :failed)
      else
        msg = "Guardfile has been re-evaluated."
        UI.info(msg)
        Notifier.notify(msg, title: "Guard re-evaluate")

        Guard.setup_scope
        Runner.new.run(:start)
      end
    ensure
      Guard.restore_scope
    end

    private

    def _evaluator
      Guardfile::Evaluator.new(Guard.options)
    end

    def _add_self_to_plugins
      # TODO: do this on reload as well
      pattern = _relative_pathname(_evaluator.path).to_s
      options = { watchers: [Watcher.new(pattern)], group: :common }
      Guard.add_plugin(:reevaluator, options)
    end
  end
end
