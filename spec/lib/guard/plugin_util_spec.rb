# frozen_string_literal: true

require "guard/plugin_util"

RSpec.describe Guard::PluginUtil, :stub_ui do
  let(:evaluator) { instance_double("Guard::Guardfile::Evaluator", evaluate: true) }

  describe ".plugin_names" do
    before do
      spec = Gem::Specification
      gems = [
        instance_double(spec, name: "guard-myplugin"),
        instance_double(spec, name: "gem1", full_gem_path: "/gem1"),
        instance_double(spec, name: "gem2", full_gem_path: "/gem2"),
        instance_double(spec, name: "guard-compat")
      ]
      allow(File).to receive(:exist?)
        .with("/gem1/lib/guard/gem1.rb") { false }

      allow(File).to receive(:exist?)
        .with("/gem2/lib/guard/gem2.rb") { true }

      gem = class_double(Gem::Specification)
      stub_const("Gem::Specification", gem)
      expect(Gem::Specification).to receive(:find_all) { gems }
      allow(Gem::Specification).to receive(:unresolved_deps) { [] }
    end

    it "returns the list of guard gems" do
      expect(described_class.plugin_names).to include("myplugin")
    end

    it "returns the list of embedded guard gems" do
      expect(described_class.plugin_names).to include("gem2")
    end

    it "ignores guard-compat" do
      expect(described_class.plugin_names).to_not include("compat")
    end
  end

  describe "#initialize" do
    it "accepts a name without guard-" do
      expect(described_class.new(evaluator, "dummy").name).to eq "dummy"
    end

    it "accepts a name with guard-" do
      expect(described_class.new(evaluator, "guard-dummy").name).to eq "dummy"
    end
  end

  describe "#initialize_plugin" do
    let(:plugin_util) { described_class.new(evaluator, "dummy") }
    let(:dummy) { stub_const("Guard::Dummy", double) }

    context "with a plugin inheriting from Guard::Plugin" do
      it "instantiate the plugin using the new API" do
        options = { watchers: ["watcher"], group: "foo" }
        expect(dummy).to receive(:new).with(options)

        plugin_util.initialize_plugin(options)
      end
    end
  end

  describe "#plugin_location" do
    subject { described_class.new(evaluator, "dummy") }

    it "returns the path of a Guard gem" do
      expect(Gem::Specification).to receive(:find_by_name)
        .with("guard-dummy") { double(full_gem_path: "gems/guard-dummy") }

      expect(subject.plugin_location).to eq "gems/guard-dummy"
    end
  end

  describe "#plugin_class" do
    it "reports an error if the class is not found" do
      expect(::Guard::UI).to receive(:error).with(/Could not load/)

      plugin = described_class.new(evaluator, "notAGuardClass")
      allow(plugin).to receive(:require).with("guard/notaguardclass")
                                        .and_raise(LoadError, "cannot load such file --")

      expect { plugin.plugin_class }.to raise_error(LoadError)
    end

    context "with a nested Guard class" do
      it "resolves the Guard class from string" do
        plugin = described_class.new(evaluator, "classname")
        expect(plugin).to receive(:require).with("guard/classname") do
          stub_const("Guard::Classname", double)
        end

        expect(plugin.plugin_class).to eq Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        plugin = described_class.new(evaluator, :classname)
        expect(plugin).to receive(:require).with("guard/classname") do
          stub_const("Guard::Classname", double)
        end

        expect(plugin.plugin_class).to eq Guard::Classname
      end
    end

    context "with a name with dashes" do
      it "returns the Guard class" do
        plugin = described_class.new(evaluator, "dashed-class-name")
        expect(plugin).to receive(:require).with("guard/dashed-class-name") do
          stub_const("Guard::DashedClassName", double)
        end

        expect(plugin.plugin_class).to eq Guard::DashedClassName
      end
    end

    context "with a name with underscores" do
      it "returns the Guard class" do
        plugin = described_class.new(evaluator, "underscore_class_name")
        expect(plugin).to receive(:require).with("guard/underscore_class_name") do
          stub_const("Guard::UnderscoreClassName", double)
        end

        expect(plugin.plugin_class).to eq Guard::UnderscoreClassName
      end
    end

    context "with a name like VSpec" do
      it "returns the Guard class" do
        plugin = described_class.new(evaluator, "vspec")
        expect(plugin).to receive(:require).with("guard/vspec") do
          stub_const("Guard::VSpec", double)
        end

        expect(plugin.plugin_class).to eq Guard::VSpec
      end
    end

    context "with an inline Guard class" do
      it "returns the Guard class" do
        plugin = described_class.new(evaluator, "inline")
        stub_const("Guard::Inline", double)

        expect(plugin).to_not receive(:require)
        expect(plugin.plugin_class).to eq Guard::Inline
      end
    end
  end

  describe "#add_to_guardfile" do
    context "when the Guard is already in the Guardfile" do
      before do
        allow(evaluator).to receive(:guardfile_include?) { true }
      end

      it "shows an info message" do
        expect(::Guard::UI).to receive(:info)
          .with "Guardfile already includes myguard guard"

        described_class.new(evaluator, "myguard").add_to_guardfile
      end
    end

    context "when Guardfile is empty" do
      let(:plugin_util) { described_class.new(evaluator, "myguard") }
      let(:plugin_class) { class_double("Guard::Plugin") }
      let(:location) { "/Users/me/projects/guard-myguard" }
      let(:gem_spec) { instance_double("Gem::Specification") }
      let(:io) { StringIO.new }

      before do
        allow(gem_spec).to receive(:full_gem_path).and_return(location)
        allow(evaluator).to receive(:guardfile_include?) { false }
        allow(Guard).to receive(:constants).and_return([:MyGuard])
        allow(Guard).to receive(:const_get).with(:MyGuard)
                                           .and_return(plugin_class)

        allow(Gem::Specification).to receive(:find_by_name)
          .with("guard-myguard").and_return(gem_spec)

        allow(plugin_class).to receive(:template).with(location)
                                                 .and_return("Template content")

        allow(File).to receive(:read).with("Guardfile") { "Guardfile content" }
        allow(File).to receive(:open).with("Guardfile", "wb").and_yield io
      end

      it "appends the template to the Guardfile" do
        plugin_util.add_to_guardfile
        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end

    context "when the Guard is not in the Guardfile" do
      let(:plugin_util) { described_class.new(evaluator, "myguard") }
      let(:plugin_class) { class_double("Guard::Plugin") }
      let(:location) { "/Users/me/projects/guard-myguard" }
      let(:gem_spec) { instance_double("Gem::Specification") }
      let(:io) { StringIO.new }

      before do
        allow(gem_spec).to receive(:full_gem_path).and_return(location)
        allow(evaluator).to receive(:guardfile_include?) { false }
        allow(Guard).to receive(:constants).and_return([:MyGuard])
        allow(Guard).to receive(:const_get).with(:MyGuard)
                                           .and_return(plugin_class)

        allow(Gem::Specification).to receive(:find_by_name)
          .with("guard-myguard").and_return(gem_spec)

        allow(plugin_class).to receive(:template).with(location)
                                                 .and_return("Template content")

        allow(File).to receive(:read).with("Guardfile") { "Guardfile content" }
        allow(File).to receive(:open).with("Guardfile", "wb").and_yield io
      end

      it "appends the template to the Guardfile" do
        plugin_util.add_to_guardfile
        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end
  end
end
