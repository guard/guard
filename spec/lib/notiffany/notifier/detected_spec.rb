require "guard/notifier/detected"

module Guard
  module Notifier
    RSpec.describe(Detected, exclude_stubs: [YamlEnvStorage]) do
      subject { described_class.new(supported) }

      let(:env) { instance_double(YamlEnvStorage) }

      let(:foo_mod) { double("foo_mod") }
      let(:bar_mod) { double("bar_mod") }
      let(:baz_mod) { double("baz_mod") }

      let(:supported) { [foo: foo_mod, baz: baz_mod] }

      before do
        allow(YamlEnvStorage).to receive(:new).and_return(env)

        allow(env).to receive(:notifiers) do
          fail "stub me: notifiers"
        end

        allow(env).to receive(:notifiers=) do |args|
          fail "stub me: notifiers=(#{args.inspect})"
        end
      end

      describe ".available" do
        context "with detected notifiers" do
          let(:available) do
            [
              { name: :foo, options: {} },
              { name: :baz, options: { opt1: 3 } }
            ]
          end

          let(:expected) { [[foo_mod, {}], [baz_mod, { opt1: 3 }]] }

          before do
            allow(env).to receive(:notifiers).and_return(available)
          end

          it "returns hash with detected notifier options" do
            expect(subject.available).to eq(expected)
          end
        end
      end

      describe ".add" do
        context "with no detected notifiers" do
          context "when unknown" do
            it "does not add the library" do
              expect(env).to_not receive(:notifiers=)
              subject.add(:unknown, {})
            end
          end
        end
      end

      describe ".detect" do
        context "with some detected notifiers" do
          before do
            allow(env).to receive(:notifiers).and_return([])
            allow(foo_mod).to receive(:available?).and_return(true)
            allow(baz_mod).to receive(:available?).and_return(false)
          end

          # TODO: should silent be really passed?
          let(:detected) { [{ name: :foo, options: { silent: true } }] }

          it "add detected notifiers to available" do
            expect(env).to receive(:notifiers=) do |args|
              expect(args).to eq(detected)
            end

            allow(env).to receive(:notifiers).and_return([], [], detected)
            subject.detect
          end
        end

        context "without any detected notifiers" do
          before do
            allow(env).to receive(:notifiers).and_return([])
            allow(foo_mod).to receive(:available?).and_return(false)
            allow(baz_mod).to receive(:available?).and_return(false)
          end

          let(:error) { described_class::NoneAvailableError }
          let(:msg) { /could not detect any of the supported notification/ }
          it { expect { subject.detect }.to raise_error(error, msg) }
        end
      end

      describe ".reset" do
        before do
          allow(env).to receive(:notifiers=)
        end

        it "resets the detected notifiers" do
          expect(env).to receive(:notifiers=).with(nil)
          subject.reset
        end
      end
    end
  end
end
