require "yaml"
require "guard/internals/environment"

RSpec.describe Guard::Internals::Environment::Dumper do
  subject { described_class.new.dump(value) }

  context "with \"abc\"" do
    let(:value) { "abc" }
    it { is_expected.to eq("abc") }
  end

  context "with 123" do
    let(:value) { 123 }
    it { is_expected.to eq("123") }
  end

  context "with nil" do
    let(:value) { nil }
    it { is_expected.to eq(nil) }
  end

  context "with a block" do
    subject do
      described_class.new.dump(value) { |data| YAML::dump(data) }
    end

    context "with a yaml string" do
      let(:value) { { foo: 3 } }
      let(:yaml) { "---\n:foo: 3\n" }
      it { is_expected.to eq(yaml) }
    end
  end
end

RSpec.describe Guard::Internals::Environment::Loader do
  context "with no block" do
    subject { described_class.new(meth).load(value) }

    context "with a normal method" do
      let(:meth) { :foo }

      context "with \"abc\"" do
        let(:value) { "abc" }
        it { is_expected.to eq("abc") }
      end
    end

    context "with a bool method" do
      let(:meth) { :foo? }

      %w(1 true foobar).each do |data|
        context "with #{data.inspect}" do
          let(:value) { data }
          it { is_expected.to eq(true) }
        end
      end

      %w(0 false).each do |data|
        context "with #{data.inspect}" do
          let(:value) { data }
          it { is_expected.to eq(false) }
        end
      end

      context "with nil" do
        let(:value) { nil }
        it { is_expected.to eq(nil) }
      end

      context "when empty string" do
        let(:value) { "" }
        it do
          expect { subject }.to raise_error(
            ArgumentError, /Can't convert empty string into Bool/
          )
        end
      end
    end
  end

  context "with a block" do
    subject do
      described_class.new(:foo).load(value) { |data| YAML::load(data) }
    end
    context "with a yaml string" do
      let(:value) { "--- foo\n...\n" }
      it { is_expected.to eq("foo") }
    end
  end
end

RSpec.describe Guard::Internals::Environment do
  let(:env) { double({}) }
  before(:each) { stub_const("ENV", env) }

  context "without integration" do

    let(:dumper) { instance_double(described_class::Dumper) }
    let(:loader) { instance_double(described_class::Loader) }

    before do
      allow(described_class::Dumper).to receive(:new).and_return(dumper)
      allow(described_class::Loader).to receive(:new).and_return(loader)
    end

    context "with any namespace" do
      let(:namespace) { "bar" }
      let(:instance) { described_class.new(namespace) }

      describe "creating a method" do
        subject { instance }

        before do
          subject.create_method(:foo)
        end

        context "when the method does not exist" do
          it { expect { is_expected.to_not raise_error } }
        end

        context "when the method already exists" do
          let(:error) { described_class::AlreadyExistsError }
          let(:message) { "Method :foo already exists" }
          specify do
            expect do
              subject.create_method(:foo)
            end.to raise_error(error, message)
          end
        end
      end

      describe "calling" do
        subject { instance }

        context "when method does not exist" do
          let(:error) { described_class::NoMethodError }
          let(:message) { "No such method :foo" }
          it { expect { subject.foo }.to raise_error(error, message) }
        end

        context "with a reader method" do

          context "with no block" do
            before { instance.create_method(meth) }

            context "with a normal method" do
              let(:meth) { :foo }
              before do
                allow(loader).to receive(:load).with("123").and_return(123)
              end

              it "returns unmarshalled stored value" do
                expect(ENV).to receive(:[]).with("bar_FOO").and_return("123")
                expect(subject.foo).to eq 123
              end
            end

            context "with a bool method" do
              let(:meth) { :foo? }

              it "references the proper ENV variable" do
                allow(loader).to receive(:load).with("false").and_return(false)
                expect(ENV).to receive(:[]).with("bar_FOO").and_return("false")
                expect(subject.foo?).to eq false
              end
            end
          end

          context "with a block" do
            before do
              instance.create_method(:foo) { |data| YAML::load(data) }
            end

            let(:value) { "---\n:foo: 5\n" }

            it "unmarshals using the block" do
              allow(ENV).to receive(:[]).with("bar_FOO").
                and_return(value)

              allow(loader).to receive(:load).with(value) do |arg, &block|
                expect(block).to be
                block.call(arg)
              end

              expect(subject.foo).to eq(foo: 5)
            end
          end

        end

        context "with a writer method" do
          before { instance.create_method(:foo=) }

          it "set the environment variable" do
            expect(ENV).to receive(:[]=).with("bar_FOO", "123")
            allow(dumper).to receive(:dump).with(123).and_return("123")
            subject.foo = 123
          end

          it "marshals and stores the value" do
            expect(ENV).to receive(:[]=).with("bar_FOO", "123")
            allow(dumper).to receive(:dump).with(123).and_return("123")
            subject.foo = 123
          end
        end

        context "with a method containing underscores" do
          before { instance.create_method(:foo_baz) }
          it "reads the correct variable" do
            expect(ENV).to receive(:[]).with("bar_FOO_BAZ").and_return("123")
            allow(loader).to receive(:load).with("123").and_return(123)
            subject.foo_baz
          end
        end

        context "with a block" do
          before do
            instance.create_method(:foo=) { |data| YAML::dump(data) }
          end

          let(:result) { "---\n:foo: 5\n" }

          it "marshals using the block" do
            allow(ENV).to receive(:[]=).with("bar_FOO", result)

            allow(dumper).to receive(:dump).with(foo: 5) do |arg, &block|
              expect(block).to be
              block.call(arg)
            end

            subject.foo = { foo: 5 }
          end
        end

        context "with an unsanitized name" do
          pending
        end
      end
    end
  end

  describe "with integration" do
    context "with any namespace" do
      let(:namespace) { "baz" }
      let(:instance) { described_class.new(namespace) }
      subject { instance }

      context "with a reader method" do
        context "with no block" do
          before { instance.create_method(:foo) }

          it "returns the stored value" do
            allow(ENV).to receive(:[]).with("baz_FOO").and_return("123")
            expect(subject.foo).to eq "123"
          end
        end

        context "with a block" do
          before do
            instance.create_method(:foo) { |data| YAML::load(data) }
          end

          it "unmarshals the value" do
            expect(ENV).to receive(:[]).with("baz_FOO").
              and_return("---\n:foo: 5\n")

            expect(subject.foo).to eq(foo: 5)
          end
        end
      end

      context "with a writer method" do
        context "with no block" do
          before { instance.create_method(:foo=) }

          it "marshals and stores the value" do
            expect(ENV).to receive(:[]=).with("baz_FOO", "123")
            subject.foo = 123
          end
        end

        context "with a block" do
          before do
            instance.create_method(:foo=) { |data| YAML::dump(data) }
          end

          it "nmarshals the value" do
            expect(ENV).to receive(:[]=).with("baz_FOO", "---\n:foo: 5\n")

            subject.foo = { foo: 5 }
          end
        end
      end
    end
  end
end
