# frozen_string_literal: true

require "guard/internals/groups"

RSpec.describe Guard::Internals::Groups do
  describe "#all" do
    let(:common) { instance_double("Guard::Group", name: :common) }
    let(:default) { instance_double("Guard::Group", name: :default) }

    before do
      allow(Guard::Group).to receive(:new).with(:common).and_return(common)
      allow(Guard::Group).to receive(:new).with(:default).and_return(default)
    end

    context "with only default groups" do
      it "initializes the groups" do
        expect(subject.all.map(&:name)).to eq %i[common default]
      end
    end

    context "with existing groups" do
      let(:frontend) { instance_double("Guard::Group", name: :frontend) }
      let(:backend) { instance_double("Guard::Group", name: :backend) }

      before do
        allow(Guard::Group).to receive(:new).with(:frontend, {})
                                            .and_return(frontend)

        allow(Guard::Group).to receive(:new).with(:backend, {})
                                            .and_return(backend)

        subject.add(:frontend)
        subject.add(:backend)
      end

      context "with no arguments" do
        let(:args) { [] }
        it "returns all groups" do
          expect(subject.all(*args)).to eq [common, default, frontend, backend]
        end
      end

      context "with a string argument" do
        it "returns an array of groups if plugins are found" do
          expect(subject.all("backend")).to eq [backend]
        end
      end

      context "with a symbol argument matching a group" do
        it "returns an array of groups if plugins are found" do
          expect(subject.all(:backend)).to eq [backend]
        end
      end

      context "with a symbol argument not matching a group" do
        it "returns an empty array when no group is found" do
          expect(subject.all(:foo)).to be_empty
        end
      end

      context "with a regexp argument matching a group" do
        it "returns an array of groups" do
          expect(subject.all(/^back/)).to eq [backend]
        end
      end

      context "with a regexp argument not matching a group" do
        it "returns an empty array when no group is found" do
          expect(subject.all(/back$/)).to be_empty
        end
      end
    end
  end

  describe "#add" do
    let(:common) { instance_double("Guard::Group", name: :common) }
    let(:default) { instance_double("Guard::Group", name: :default) }

    before do
      allow(Guard::Group).to receive(:new).with(:common).and_return(common)
      allow(Guard::Group).to receive(:new).with(:default).and_return(default)
    end

    context "with existing groups" do
      let(:frontend) { instance_double("Guard::Group", name: :frontend) }
      let(:backend) { instance_double("Guard::Group", name: :backend) }

      before do
        allow(Guard::Group).to receive(:new).with("frontend", {})
                                            .and_return(frontend)

        subject.add("frontend")
      end

      it "add the given group" do
        subject.add("frontend")
        expect(subject.all).to match_array([common, default, frontend])
      end

      it "add the given group with options" do
        subject.add("frontend", foo: :bar)
        expect(subject.all).to match_array([common, default, frontend])
      end

      context "with an existing group" do
        before { subject.add("frontend") }

        it "does not add duplicate groups when name is a string" do
          subject.add("frontend")
          expect(subject.all).to match_array([common, default, frontend])
        end

        it "does not add duplicate groups when name is a symbol" do
          subject.add(:frontend)
          expect(subject.all).to match_array([common, default, frontend])
        end

        it "does not add duplicate groups even if options are different" do
          subject.add(:frontend, halt_on_fail: true)
          subject.add(:frontend, halt_on_fail: false)

          expect(subject.all).to match_array([common, default, frontend])
        end
      end
    end
  end
end
