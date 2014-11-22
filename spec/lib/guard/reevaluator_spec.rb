require "guard/plugin"

require "guard/reevaluator.rb"
require "guard/ui"

RSpec.describe Guard::Reevaluator do
  let(:options) { {} }
  let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }

  subject do
    described_class.new(options)
  end

  before do
    allow(::Guard).to receive(:save_scope)
    allow(::Guard).to receive(:restore_scope)

    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
  end

  context "when Guardfile is modified" do
    let(:watcher) { instance_double("Guard::Watcher") }
    before do
      allow(Guard).to receive(:add_plugin).with(:reevaluator, anything)
      allow(::Guard::Watcher).to receive(:new). and_return(watcher)

      expect(evaluator).to receive(:guardfile_path).
        and_return(File.expand_path("Guardfile"))
    end

    it "should reevaluate guardfile" do
      expect(evaluator).to receive(:reevaluate_guardfile)
      subject.run_on_modifications(["Guardfile"])
    end

    context "when Guardfile contains errors" do
      let(:failure) { proc { fail "Could not load Foo!" } }

      before do
        allow(evaluator).to receive(:reevaluate_guardfile) { failure.call }
      end

      context "with a name error" do
        let(:failure) { proc { fail NameError, "Could not load Foo!" } }
        it "should notify guard it failed to prevent being fired" do
          expect { subject.run_on_modifications(["Guardfile"]) }.
            to throw_symbol(:task_has_failed)
        end
      end

      context "with a syntax error" do
        let(:failure) { proc { fail SyntaxError, "Could not load Foo!" } }
        it "should notify guard it failed to prevent being fired" do
          expect { subject.run_on_modifications(["Guardfile"]) }.
            to throw_symbol(:task_has_failed)
        end
      end

      # TODO: show backtrace?
      it "should show warning about the error" do
        expect(::Guard::UI).to receive(:warning).
          with("Failed to reevaluate file: Could not load Foo!")

        catch(:task_has_failed) do
          subject.run_on_modifications(["Guardfile"])
        end
      end

      it "should restore the scope" do
        expect(::Guard).to receive(:restore_scope)

        catch(:task_has_failed) do
          subject.run_on_modifications(["Guardfile"])
        end
      end

      it "should notify eval failed with a :task_has_failed error" do
        expect { subject.run_on_modifications(["Guardfile"]) }.
          to throw_symbol(:task_has_failed)
      end

      it "should add itself as an active plugin" do
        watcher = instance_double(::Guard::Watcher)

        # TODO: the right pattern? Other custom Guardfile locations?
        expect(::Guard::Watcher).to receive(:new).with("Guardfile").
          and_return(watcher)

        options = { watchers: [watcher] }
        expect(::Guard).to receive(:add_plugin).with(:reevaluator, options)

        catch(:task_has_failed) do
          subject.run_on_modifications(["Guardfile"])
        end
      end
    end
  end

  context "when Guardfile is not modified" do
    it "should not reevaluate guardfile" do
      expect(evaluator).to receive(:guardfile_path).and_return("Guard.bar")
      expect(evaluator).to_not receive(:reevaluate_guardfile)
      subject.run_on_modifications(["foo"])
    end
  end
end
