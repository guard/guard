require "guard/config"

unless Guard::Config.new.strict?

  require "guard/deprecated/watcher"

  RSpec.describe Guard::Deprecated::Watcher do
    subject do
      module TestModule; end.tap { |mod| described_class.add_deprecated(mod) }
    end

    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }
    let(:options) { { guardfile: "foo" } }

    before do
      allow(Guard).to receive(:options).and_return(options)

      allow(evaluator).to receive(:guardfile_path).
        and_return(File.expand_path("foo"))

      allow(::Guard::Guardfile::Evaluator).to receive(:new).with(options).
        and_return(evaluator)

      allow(Guard::UI).to receive(:deprecation)
    end

    describe ".match_guardfile?" do
      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Watcher::ClassMethods::MATCH_GUARDFILE)

        files = %w(foo bar)
        subject.match_guardfile?(files)
      end

      it "matches against current guardfile" do
        expect(subject.match_guardfile?(%w(foo bar))).to be(true)
        expect(subject.match_guardfile?(%w(bar))).to be(false)
      end
    end
  end
end
