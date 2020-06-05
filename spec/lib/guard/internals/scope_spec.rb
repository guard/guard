# frozen_string_literal: true

require "guard/internals/scope"

RSpec.describe Guard::Internals::Scope do
  include_context "with engine"

  let!(:frontend_group) { groups.add("frontend") }
  let!(:dummy_plugin) { plugins.add("dummy", group: "frontend", watchers: [Guard::Watcher.new("hello")]) }

  subject { engine.scope }

  # TODO: move to Session?
  describe "#titles" do
    context "with no arguments given" do
      it "returns 'Dummy'" do
        expect(subject.titles).to eq ["Dummy"]
      end
    end

    context "with a 'plugins' scope given" do
      it "returns the plugins' titles" do
        expect(subject.titles(plugins: [:dummy])).to eq ["Dummy"]
      end
    end

    context "with a 'groups' scope given" do
      it "returns the groups' titles" do
        expect(subject.titles(groups: [:frontend])).to eq %w[Frontend Common]
      end
    end

    context "with both 'plugins' and 'groups' scopes given" do
      it "returns only the plugins' titles" do
        expect(subject.titles(plugins: [dummy_plugin], groups: [frontend_group])).to eq ["Dummy"]
      end
    end

    shared_examples "scopes titles" do
      it "return the titles for the given scopes" do
        expect(subject.titles).to eq engine.public_send(given_scope).all(name_for_scope).map(&:title)
      end
    end

    shared_examples "empty scopes titles" do
      it "return an empty array" do
        expect(subject.titles).to be_empty
      end
    end

    { groups: "frontend", plugins: "dummy" }.each do |scope, name|
      let(:given_scope) { scope }
      let(:name_for_scope) { name }

      describe "#{scope.inspect} (#{name})" do
        context "when set from interactor" do
          before do
            engine.session.interactor_scopes = { given_scope => name_for_scope }
          end

          it_behaves_like "scopes titles"
        end

        context "when not set in interactor" do
          context "when set in commandline" do
            let(:options) { { given_scope => [name_for_scope] } }

            it_behaves_like "scopes titles"
          end

          context "when not set in commandline" do
            context "when set in Guardfile" do
              before do
                engine.session.guardfile_scopes = { given_scope => name_for_scope }
              end

              it_behaves_like "scopes titles"
            end
          end
        end
      end
    end

    describe "with groups and plugins scopes" do
      before do
        engine.session.interactor_scopes = { groups: "frontend", plugins: "dummy" }
      end

      it "return only the plugins titles" do
        expect(subject.titles).to eq engine.plugins.all.map(&:title)
      end
    end
  end
end
