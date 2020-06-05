# frozen_string_literal: true

require "guard/guardfile/evaluator"
require "guard/engine"
require "guard/plugin"

RSpec.describe Guard::Guardfile::Evaluator, :stub_ui do
  let(:options) { {} }
  let(:engine) { Guard::Engine.new(options) }
  let(:valid_guardfile_string) { "group :foo; do guard :bar; end; end; " }
  let(:dsl) { instance_double("Guard::Dsl") }

  subject { described_class.new(engine) }

  before do
    Guard::Dummy = Class.new(Guard::Plugin)
    stub_user_guard_rb
    allow(Guard::Dsl).to receive(:new).with(engine).and_return(dsl)
  end

  after do
    Guard.__send__(:remove_const, :Dummy)
  end

  describe ".evaluate" do
    describe "error cases" do
      context "with an invalid Guardfile" do
        let(:options) { { inline: "guard :foo Bad Guardfile" } }

        it "displays an error message and raises original exception" do
          expect(dsl).to receive(:evaluate)
            .and_raise(Guard::Dsl::Error,
                       "Invalid Guardfile, original error is:")

          expect { subject.evaluate }.to raise_error(Guard::Dsl::Error)
        end
      end

      context "with no Guardfile at all" do
        it "displays an error message and exits" do
          stub_guardfile_rb
          stub_guardfile
          stub_user_guardfile
          stub_user_project_guardfile

          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoGuardfileError)
        end
      end

      context "with Guardfile as guardfile.rb" do
        it "evalutates guardfile.rb" do
          stub_guardfile_rb("guard :dummy")

          expect(dsl).to receive(:evaluate).with("guard :dummy", anything, 1)

          subject.evaluate
        end
      end

      context "with a problem reading a Guardfile" do
        let(:path) { File.expand_path("Guardfile") }

        before do
          stub_user_project_guardfile
          stub_guardfile_rb
          stub_guardfile(" ") do
            fail Errno::EACCES.new("permission error")
          end
        end

        it "displays an error message and exits" do
          expect(Guard::UI).to receive(:error).with(/^Error reading file/)
          expect { subject.evaluate }.to raise_error(SystemExit)
        end
      end

      context "with empty Guardfile content" do
        let(:options) { { inline: "" } }

        it "displays an error message about no plugins" do
          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoPluginsError)
        end
      end

      context "when provided :inline is nil" do
        let(:options) { { inline: nil } }

        before do
          stub_guardfile("guard :dummy")

          stub_guardfile_rb
        end

        it "does not raise error and skip it" do
          expect(dsl).to receive(:evaluate).with("guard :dummy", anything, 1)

          expect(Guard::UI).to_not receive(:error)
          expect do
            described_class.new(engine).evaluate
          end.to_not raise_error
        end
      end

      context "with a non-existing Guardfile given" do
        let(:non_existing_path) { "/non/existing/path/to/Guardfile" }
        let(:options) { { guardfile: non_existing_path } }

        before do
          stub_file(non_existing_path)
        end

        it "raises error" do
          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoCustomGuardfile)
        end
      end
    end

    describe "selection of the Guardfile data contents" do
      context "with a valid :contents option" do
        context "with inline content and other Guardfiles available" do
          let(:inline_code) { "guard :dummy" }
          let(:options) do
            {
              inline: inline_code,
              guardfile: "/abc/Guardfile"
            }
          end

          before do
            stub_file("/abc/Guardfile", "guard :bar")
            stub_guardfile_rb("guard :baz")
            stub_guardfile("guard :baz")
            stub_user_guardfile("guard :buz")
          end

          it "gives ultimate precedence to inline content" do
            expect(dsl).to receive(:evaluate).with(inline_code, "", 1)

            subject.evaluate
          end
        end
      end

      context "with the :guardfile option" do
        let(:options) { { guardfile: "../relative_path_to_Guardfile" } }

        before do
          stub_file(File.expand_path(options[:guardfile]),
                    valid_guardfile_string)

          expect(dsl).to receive(:evaluate)
            .with(valid_guardfile_string, anything, 1)
        end
      end
    end
  end

  describe "#inline?" do
    context "when no content is provided" do
      it { is_expected.to_not be_inline }
    end

    context "when guardfile_contents is provided" do
      let(:options) { { inline: "guard :dummy" } }

      it { is_expected.to be_inline }
    end
  end

  describe ".guardfile_include?" do
    context "when plugin is present" do
      let(:options) { { inline: 'guard :dummy do watch("c") end' } }

      it "returns true" do
        expect(subject).to be_guardfile_include("dummy")
      end
    end

    context "when plugin is not present" do
      let(:options) { { inline: 'guard :other do watch("c") end' } }

      it "returns false" do
        expect(subject).not_to be_guardfile_include("test")
      end
    end
  end
end
