# frozen_string_literal: true

require "guard/watcher"
require "guard/plugin"

RSpec.describe Guard::Watcher, :stub_ui do
  let(:args) { [] }
  subject { described_class.new(*args) }
  describe "#initialize" do
    context "with no arguments" do
      let(:args) { [] }
      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "with a pattern parameter" do
      let(:pattern) { ["spec_helper.rb"] }
      let(:args) { [pattern] }

      it "creates a matcher" do
        expect(described_class::Pattern).to receive(:create).with(pattern)
        subject
      end
    end
  end

  describe "#action" do
    it "sets the action to nothing by default" do
      expect(described_class.new(/spec_helper\.rb/).action).to be_nil
    end

    it "sets the action to the supplied block" do
      action = ->(m) { "spec/#{m[1]}_spec.rb" }
      expect(described_class.new(%r{^lib/(.*).rb}, action).action).to eq action
    end
  end

  describe "#==" do
    it "returns true for equal watchers" do
      expect(described_class.new(/spec_helper\.rb/))
        .to eq(described_class.new(/spec_helper\.rb/))
    end

    it "returns false for unequal watchers" do
      expect(described_class.new(/spec_helper\.rb/))
        .not_to eq(described_class.new(/spec_helper\.r/))
    end
  end

  describe ".match_files" do
    let(:plugin) { instance_double("Guard::Plugin", options: {}) }

    def matched(files)
      described_class.match_files(plugin, files)
    end

    context "without a watcher action" do
      before do
        allow(plugin).to receive(:watchers)
          .and_return([described_class.new(pattern)])
      end

      context "with a regex pattern" do
        let(:pattern) { /.*_spec\.rb/ }
        it "returns the paths that matches the regex" do
          expect(matched(%w[foo_spec.rb foo.rb])).to eq %w[foo_spec.rb]
        end
      end

      context "with a string pattern" do
        let(:pattern) { "foo_spec.rb" }
        it "returns the path that matches the string" do
          expect(matched(%w[foo_spec.rb foo.rb])).to eq ["foo_spec.rb"]
        end
      end
    end

    context "with a watcher action without parameter" do
      context "for a watcher that matches file strings" do
        before do
          klass = described_class
          allow(plugin).to receive(:watchers).and_return(
            [
              klass.new("spec_helper.rb", -> { "spec" }),
              klass.new("addition.rb", -> { 1 + 1 }),
              klass.new("hash.rb", -> { Hash[:foo, "bar"] }),
              klass.new("array.rb", -> { %w[foo bar] }),
              klass.new("blank.rb", -> { "" }),
              klass.new(/^uptime\.rb/, -> { "" })
            ]
          )
        end

        it "returns a single file specified within the action" do
          expect(matched(%w[spec_helper.rb])).to eq ["spec"]
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w[hash.rb])).to eq %w[foo bar]
        end

        it "combines files from results of different actions" do
          expect(matched(%w[spec_helper.rb array.rb])).to eq %w[spec foo bar]
        end

        context "when action returns non-string or array of non-strings" do
          it "returns nothing" do
            expect(matched(%w[addition.rb])).to eq []
          end
        end

        it "returns nothing if the action response is empty" do
          expect(matched(%w[blank.rb])).to eq []
        end

        it "returns nothing if the action returns nothing" do
          expect(matched(%w[uptime.rb])).to eq []
        end
      end

      context "for a watcher that matches information objects" do
        before do
          allow(plugin).to receive(:options).and_return(any_return: true)

          klass = described_class
          allow(plugin).to receive(:watchers).and_return(
            [
              klass.new("spec_helper.rb", -> { "spec" }),
              klass.new("addition.rb", -> { 1 + 1 }),
              klass.new("hash.rb", -> { Hash[:foo, "bar"] }),
              klass.new("array.rb", -> { %w[foo bar] }),
              klass.new("blank.rb", -> { "" }),
              klass.new(/^uptime\.rb/, -> { "" })
            ]
          )
        end

        it "returns a single file specified within the action" do
          expect(matched(%w[spec_helper.rb]).class).to be Array
          expect(matched(%w[spec_helper.rb])).to_not be_empty
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w[hash.rb])).to eq [{ foo: "bar" }]
        end

        it "combines the results of different actions" do
          expect(matched(%w[spec_helper.rb array.rb]))
            .to eq ["spec", %w[foo bar]]
        end

        it "returns the evaluated addition argument in an array" do
          expect(matched(%w[addition.rb]).class).to be(Array)
          expect(matched(%w[addition.rb])[0]).to eq 2
        end

        it "returns nothing if the action response is empty string" do
          expect(matched(%w[blank.rb])).to eq [""]
        end

        it "returns nothing if the action returns empty string" do
          expect(matched(%w[uptime.rb])).to eq [""]
        end
      end
    end

    context "with a watcher action that takes a parameter" do
      context "for a watcher that matches file strings" do
        before do
          klass = described_class
          allow(plugin).to receive(:watchers).and_return [
            klass.new(%r{lib/(.*)\.rb}, ->(m) { "spec/#{m[1]}_spec.rb" }),
            klass.new(/addition(.*)\.rb/, ->(_m) { 1 + 1 }),
            klass.new("hash.rb", ->(_m) { Hash[:foo, "bar"] }),
            klass.new(/array(.*)\.rb/, ->(_m) { %w[foo bar] }),
            klass.new(/blank(.*)\.rb/, ->(_m) { "" }),
            klass.new(/^uptime\.rb/, -> { "" })
          ]
        end

        it "returns a substituted single file specified within the action" do
          expect(matched(%w[lib/foo.rb])).to eq ["spec/foo_spec.rb"]
        end

        it "returns multiple files specified within the action" do
          expect(matched(%w[hash.rb])).to eq %w[foo bar]
        end

        it "combines results of different actions" do
          expect(matched(%w[lib/foo.rb array.rb]))
            .to eq %w[spec/foo_spec.rb foo bar]
        end

        it "returns nothing if action returns non-string or non-string array" do
          expect(matched(%w[addition.rb])).to eq []
        end

        it "returns nothing if the action response is empty" do
          expect(matched(%w[blank.rb])).to eq []
        end

        it "returns nothing if the action returns nothing" do
          expect(matched(%w[uptime.rb])).to eq []
        end
      end

      context "for a watcher that matches information objects" do
        before do
          allow(plugin).to receive(:options).and_return(any_return: true)

          kl = described_class
          allow(plugin).to receive(:watchers).and_return(
            [
              kl.new(%r{lib/(.*)\.rb}, ->(m) { "spec/#{m[1]}_spec.rb" }),
              kl.new(/addition(.*)\.rb/, ->(m) { (1 + 1).to_s + m[0] }),
              kl.new("hash.rb", ->(m) { { foo: "bar", file_name: m[0] } }),
              kl.new(/array(.*)\.rb/, ->(m) { ["foo", "bar", m[0]] }),
              kl.new(/blank(.*)\.rb/, ->(_m) { "" }),
              kl.new(/^uptime\.rb/, -> { "" })
            ]
          )
        end

        it "returns a substituted single file specified within the action" do
          expect(matched(%w[lib/foo.rb])).to eq %w[spec/foo_spec.rb]
        end

        it "returns a hash specified within the action" do
          expect(matched(%w[hash.rb])).to eq [
            { foo: "bar", file_name: "hash.rb" }
          ]
        end

        it "combinines results of different actions" do
          expect(matched(%w[lib/foo.rb array.rb]))
            .to eq ["spec/foo_spec.rb", %w[foo bar array.rb]]
        end

        it "returns the evaluated addition argument + the path" do
          expect(matched(%w[addition.rb])).to eq ["2addition.rb"]
        end

        it "returns nothing if the action response is empty string" do
          expect(matched(%w[blank.rb])).to eq [""]
        end

        it "returns nothing if the action returns is IO::NULL" do
          expect(matched(%w[uptime.rb])).to eq [""]
        end
      end
    end

    context "with an exception that is raised" do
      before do
        allow(plugin).to receive(:watchers).and_return(
          [described_class.new("evil.rb", -> { fail "EVIL" })]
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
          described_class.new("awesome_helper.rb", -> {}),
          described_class.new(/.+some_helper.rb/, -> { "foo.rb" }),
          described_class.new(/.+_helper.rb/, -> { "bar.rb" })
        ]
      end

      context "when the :first_match option is turned off" do
        before do
          allow(plugin).to receive(:options).and_return(first_match: false)
        end

        it "returns multiple files by combining the results of the watchers" do
          expect(described_class.match_files(plugin, ["awesome_helper.rb"])).to eq(["foo.rb", "bar.rb"])
        end
      end

      context "when the :first_match option is turned on" do
        before do
          plugin.options[:first_match] = true
        end

        it "returns only the files from the first watcher" do
          expect(described_class.match_files(plugin, ["awesome_helper.rb"])).to eq(["foo.rb"])
        end
      end
    end
  end

  describe "#match" do
    subject { described_class.new(pattern).match(file) }

    let(:matcher) { instance_double(described_class::Pattern::Matcher) }
    let(:match) { instance_double(described_class::Pattern::MatchResult) }

    before do
      allow(described_class::Pattern).to receive(:create).with(pattern)
                                                         .and_return(matcher)

      allow(matcher).to receive(:match).with(pattern)
                                       .and_return(match_data)

      allow(described_class::Pattern::MatchResult).to receive(:new)
        .with(match_data, file).and_return(match)
    end

    context "with a valid pattern" do
      let(:pattern) { "foo.rb" }
      context "with a valid file name to match" do
        let(:file) { "foo.rb" }
        context "when matching is successful" do
          let(:match_data) { double("match data", to_a: ["foo"]) }
          it "returns the match result" do
            expect(subject).to be(match)
          end
        end

        context "when matching is not successful" do
          let(:match_data) { nil }
          it "returns nil" do
            expect(subject).to be_nil
          end
        end
      end
    end
  end

  describe "integration" do
    describe "#match" do
      subject { described_class.new(pattern) }
      context "with a named regexp pattern" do
        let(:pattern) { /(?<foo>.*)_spec\.rb/ }

        context "with a watcher that matches a file" do
          specify do
            expect(subject.match("bar_spec.rb")[0]).to eq("bar_spec.rb")
            expect(subject.match("bar_spec.rb")[1]).to eq("bar")
          end

          it "provides the match by name" do
            expect(subject.match("bar_spec.rb")[:foo]).to eq("bar")
          end
        end
      end
    end
  end
end
