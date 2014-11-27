require "guard/watcher"

# TODO: shouldn't be needed
require "guard/guardfile/evaluator"

RSpec.describe Guard::Watcher do

  describe "#initialize" do
    it "requires a pattern parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    context "with a pattern parameter" do
      context "that is a string" do
        it "keeps the string pattern unmodified" do
          expect(described_class.new("spec_helper.rb").pattern).
            to eq "spec_helper.rb"
        end
      end

      context "that is a regexp" do
        it "keeps the regex pattern unmodified" do
          expect(described_class.new(/spec_helper\.rb/).pattern).
            to eq(/spec_helper\.rb/)
        end
      end

      context "that is a string looking like a regex (deprecated)" do
        before(:each) { allow(Guard::UI).to receive(:info) }

        it "converts the string automatically to a regex" do
          expect(described_class.new("^spec_helper.rb").pattern).
            to eq(/^spec_helper.rb/)
          expect(described_class.new("spec_helper.rb$").pattern).
            to eq(/spec_helper.rb$/)
          expect(described_class.new('spec_helper\.rb').pattern).
            to eq(/spec_helper\.rb/)
          expect(described_class.new(".*_spec.rb").pattern).
            to eq(/.*_spec.rb/)
        end
      end
    end
  end

  describe "#action" do
    it "sets the action to nothing by default" do
      expect(described_class.new(/spec_helper\.rb/).action).to be_nil
    end

    it "sets the action to the supplied block" do
      action = lambda { |m| "spec/#{m[1]}_spec.rb" }
      expect(described_class.new(%r{^lib/(.*).rb}, action).action).to eq action
    end
  end

  describe ".match_files" do
    let(:plugin) { instance_double("Guard::Plugin", options: {}) }

    def matched(files)
      described_class.match_files(plugin, files)
    end

    context "with a watcher without action" do
      before do
        allow(plugin).to receive(:watchers).
          and_return([described_class.new(pattern)])
      end

      context "that is a regex pattern" do
        let(:pattern) { /.*_spec\.rb/ }
        it "returns the paths that matches the regex" do
          expect(matched(%w(foo_spec.rb foo.rb))).to eq %w(foo_spec.rb)
        end
      end

      context "that is a string pattern" do
        let(:pattern) { "foo_spec.rb" }
        it "returns the path that matches the string" do
          expect(matched(%w(foo_spec.rb foo.rb))).to eq ["foo_spec.rb"]
        end
      end
    end

    context "with a watcher action without parameter" do
      context "for a watcher that matches file strings" do
        before do
          klass = described_class
          allow(plugin).to receive(:watchers).and_return([
            klass.new("spec_helper.rb", lambda { "spec" }),
            klass.new("addition.rb", lambda { 1 + 1 }),
            klass.new("hash.rb", lambda { Hash[:foo, "bar"] }),
            klass.new("array.rb", lambda { %w(foo bar) }),
            klass.new("blank.rb", lambda { "" }),
            klass.new(/^uptime\.rb/, lambda { "" })
          ])
        end

        it "returns a single file specified within the action" do
          expect(matched(%w(spec_helper.rb))).to eq ["spec"]
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w(hash.rb))).to eq %w(foo bar)
        end

        it "combines files from results of different actions" do
          expect(matched(%w(spec_helper.rb array.rb))).to eq %w(spec foo bar)
        end

        context "when action returns non-string or array of non-strings" do
          it "returns nothing" do
            expect(matched(%w(addition.rb))).to eq []
          end
        end

        it "returns nothing if the action response is empty" do
          expect(matched(%w(blank.rb))).to eq []
        end

        it "returns nothing if the action returns nothing" do
          expect(matched(%w(uptime.rb))).to eq []
        end
      end

      context "for a watcher that matches information objects" do
        before do
          allow(plugin).to receive(:options).and_return(any_return: true)

          klass = described_class
          allow(plugin).to receive(:watchers).and_return([
            klass.new("spec_helper.rb", lambda { "spec" }),
            klass.new("addition.rb", lambda { 1 + 1 }),
            klass.new("hash.rb", lambda { Hash[:foo, "bar"] }),
            klass.new("array.rb", lambda { %w(foo bar) }),
            klass.new("blank.rb", lambda { "" }),
            klass.new(/^uptime\.rb/, lambda { "" })
          ])
        end

        it "returns a single file specified within the action" do
          expect(matched(%w(spec_helper.rb)).class).to be Array
          expect(matched(%w(spec_helper.rb))).to_not be_empty
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w(hash.rb))).to eq [{ foo: "bar" }]
        end

        it "combines the results of different actions" do
          expect(matched(%w(spec_helper.rb array.rb))).
                 to eq ["spec", %w(foo bar)]
        end

        it "returns the evaluated addition argument in an array" do
          expect(matched(%w(addition.rb)).class).to be(Array)
          expect(matched(%w(addition.rb))[0]).to eq 2
        end

        it "returns nothing if the action response is empty string" do
          expect(matched(%w(blank.rb))).to eq [""]
        end

        it "returns nothing if the action returns empty string" do
          expect(matched(%w(uptime.rb))).to eq [""]
        end
      end
    end

    context "with a watcher action that takes a parameter" do
      context "for a watcher that matches file strings" do
        before do
          klass = described_class
          allow(plugin).to receive(:watchers).and_return [
            klass.new(%r{lib/(.*)\.rb}, lambda { |m| "spec/#{m[1]}_spec.rb" }),
            klass.new(/addition(.*)\.rb/, lambda { |_m| 1 + 1 }),
            klass.new("hash.rb",  lambda { |_m| Hash[:foo, "bar"] }),
            klass.new(/array(.*)\.rb/, lambda { |_m| %w(foo bar) }),
            klass.new(/blank(.*)\.rb/, lambda { |_m| "" }),
            klass.new(/^uptime\.rb/, lambda { "" })
          ]
        end

        it "returns a substituted single file specified within the action" do
          expect(matched(%w(lib/foo.rb))).to eq ["spec/foo_spec.rb"]
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w(hash.rb))).to eq %w(foo bar)
        end

        it "combines results of different actions" do
          expect(matched(%w(lib/foo.rb array.rb))).
            to eq %w(spec/foo_spec.rb foo bar)
        end

        it "returns nothing if action returns non-string or non-string array" do
          expect(matched(%w(addition.rb))).to eq []
        end

        it "returns nothing if the action response is empty" do
          expect(matched(%w(blank.rb))).to eq []
        end

        it "returns nothing if the action returns nothing" do
          expect(matched(%w(uptime.rb))).to eq []
        end
      end

      context "for a watcher that matches information objects" do
        before do
          allow(plugin).to receive(:options).and_return(any_return: true)

          kl = described_class
          allow(plugin).to receive(:watchers).and_return([
            kl.new(%r{lib/(.*)\.rb}, lambda { |m| "spec/#{m[1]}_spec.rb" }),
            kl.new(/addition(.*)\.rb/, lambda { |m| (1 + 1).to_s + m[0] }),
            kl.new("hash.rb", lambda { |m| { foo: "bar", file_name: m[0] } }),
            kl.new(/array(.*)\.rb/, lambda { |m| ["foo", "bar", m[0]] }),
            kl.new(/blank(.*)\.rb/, lambda { |_m| "" }),
            kl.new(/^uptime\.rb/, lambda { "" })
          ])
        end

        it "returns a substituted single file specified within the action" do
          expect(matched(%w(lib/foo.rb))).to eq %w(spec/foo_spec.rb)
        end

        it "returns a hash specified within the action" do
          expect(matched(%w(hash.rb))).to eq [
            { foo: "bar", file_name: "hash.rb" }
          ]
        end

        it "combinines results of different actions" do
          expect(matched(%w(lib/foo.rb array.rb))).
            to eq ["spec/foo_spec.rb", %w(foo bar array.rb)]
        end

        it "returns the evaluated addition argument + the path" do
          expect(matched(%w(addition.rb))).to eq ["2addition.rb"]
        end

        it "returns nothing if the action response is empty string" do
          expect(matched(%w(blank.rb))).to eq [""]
        end

        it "returns nothing if the action returns is IO::NULL" do
          expect(matched(%w(uptime.rb))).to eq [""]
        end
      end
    end

    context "with an exception that is raised" do
      before do
        allow(plugin).to receive(:watchers).and_return(
          [described_class.new("evil.rb", lambda { fail "EVIL" })]
        )
      end

      it "displays the error and backtrace" do
        expect(Guard::UI).to receive(:error) do |msg|
          expect(msg).to include("Problem with watch action!")
          expect(msg).to include("EVIL")
        end

        described_class.match_files(plugin, ["evil.rb"])
      end
    end

    context "for ambiguous watchers" do
      before do
        expect(plugin).to receive(:watchers).and_return [
          described_class.new("awesome_helper.rb", lambda {}),
          described_class.new(/.+some_helper.rb/, lambda { "foo.rb" }),
          described_class.new(/.+_helper.rb/, lambda { "bar.rb" }),
        ]
      end

      context "when the :first_match option is turned off" do
        before do
          allow(plugin).to receive(:options).and_return(first_match: false)
        end

        it "returns multiple files by combining the results of the watchers" do
          expect(described_class.match_files(
            plugin, ["awesome_helper.rb"])).to eq(["foo.rb", "bar.rb"])
        end
      end

      context "when the :first_match option is turned on" do
        before do
          plugin.options[:first_match] = true
        end

        it "returns only the files from the first watcher" do
          expect(described_class.match_files(
            plugin, ["awesome_helper.rb"])).to eq(["foo.rb"])
        end
      end
    end
  end

  describe ".match_files?" do
    pending
  end

  describe ".match" do
    subject { described_class.new(pattern).match(file) }

    context "with a file name pattern" do
      let(:pattern) { "guard_rocks_spec.rb" }

      context "with matching normal file" do
        let(:file) { "guard_rocks_spec.rb" }
        it { is_expected.to eq ["guard_rocks_spec.rb"] }
      end

      context "with matching pathname" do
        let(:file) { Pathname("guard_rocks_spec.rb") }
        it { is_expected.to eq ["guard_rocks_spec.rb"] }
      end

      context "with not-matching normal file" do
        let(:file) { "lib/my_wonderful_lib.rb" }
        it { is_expected.to be_nil }
      end

      context "with matching file containing $" do
        let(:pattern) { "lib$/guard_rocks_spec.rb" }
        let(:file) { "lib$/guard_rocks_spec.rb" }
        it { is_expected.to eq ["lib$/guard_rocks_spec.rb"] }
      end
    end

    context "with a string representing a regexp (deprecated)" do
      let(:pattern) { '^guard_(rocks)_spec\.rb$' }

      context "with matching normal file" do
        let(:file) { "guard_rocks_spec.rb" }
        it { is_expected.to eq ["guard_rocks_spec.rb", "rocks"] }
      end

      context "with not-matching normal file" do
        let(:file) { "lib/my_wonderful_lib.rb" }
        it { is_expected.to be_nil }
      end
    end

    context "with a regexp pattern" do
      subject { described_class.new(/(.*)_spec\.rb/) }

      context "with a watcher that matches a file" do
        specify do
          expect(subject.match("guard_rocks_spec.rb")).
            to eq ["guard_rocks_spec.rb", "guard_rocks"]
        end
      end

      context "with a file containing a $" do
        specify do
          result = subject.match("lib$/guard_rocks_spec.rb")
          expect(result).to eq ["lib$/guard_rocks_spec.rb", "lib$/guard_rocks"]
        end
      end

      context "with no watcher that matches a file" do
        specify { expect(subject.match("lib/my_wonderful_lib.rb")).to be_nil }
      end
    end
  end
end
