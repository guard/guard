require 'spec_helper'

require 'guard/plugin'

describe Guard::PluginUtil do

  let!(:rubygems_version_1_7_2) { Gem::Version.create('1.7.2') }
  let!(:rubygems_version_1_8_0) { Gem::Version.create('1.8.0') }
  let(:guard_rspec_class) { double('Guard::RSpec') }
  let(:guard_rspec) { double('Guard::RSpec instance') }
  let(:guardfile_evaluator) { double('Guard::Guardfile::Evaluator instance') }

  before do
    Guard.setup
  end

  describe '.plugin_names' do
    context 'Rubygems < 1.8.0' do
      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        expect(Gem::Version).to receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems_source_index = double
        expect(Gem).to receive(:source_index) { gems_source_index }
        expect(gems_source_index).to receive(:find_name).with(/^guard-/) { [double(name: 'guard-rspec'), double(name: 'guard-rspec')] }
      end

      it 'returns the list of guard gems' do
        expect(described_class.plugin_names).to eq ['rspec']
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        expect(Gem::Version).to receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems = [
          double(name: 'guard'),
          double(name: 'guard-rspec'),
          double(name: 'gem1', full_gem_path: '/gem1'),
          double(name: 'gem2', full_gem_path: '/gem2'),
        ]
        File.stub(:exists?).with('/gem1/lib/guard/gem1.rb') { false }
        File.stub(:exists?).with('/gem2/lib/guard/gem2.rb') { true }
        expect(Gem::Specification).to receive(:find_all) { gems }
      end

      it "returns the list of guard gems" do
        expect(described_class.plugin_names).to include('rspec')
      end

      it "returns the list of embedded guard gems" do
        expect(described_class.plugin_names).to include('gem2')
      end
    end
  end

  describe '#initialize' do
    it 'accepts a name without guard-' do
      expect(described_class.new('rspec').name).to eq 'rspec'
    end

    it 'accepts a name with guard-' do
      expect(described_class.new('guard-rspec').name).to eq 'rspec'
    end
  end

  describe '#initialize_plugin' do
    let(:plugin_util) { described_class.new('rspec') }

    before do
      described_class.any_instance.stub(:plugin_class).and_return(guard_rspec_class)
    end

    context 'with a plugin inheriting from Guard::Guard (deprecated)' do
      before { expect(guard_rspec_class).to receive(:superclass) { ::Guard::Guard } }

      it 'instantiate the plugin using the old API' do
        expect(guard_rspec_class).to receive(:new).with(['watcher'], group: 'foo').and_return(guard_rspec)

        expect(plugin_util.initialize_plugin(watchers: ['watcher'], group: 'foo')).to eq guard_rspec
      end
    end

    context 'with a plugin inheriting from Guard::Plugin' do
      before { expect(guard_rspec_class).to receive(:superclass) { ::Guard::Plugin } }

      it 'instantiate the plugin using the new API' do
        expect(guard_rspec_class).to receive(:new).with(watchers: ['watcher'], group: 'foo').and_return(guard_rspec)

        expect(plugin_util.initialize_plugin(watchers: ['watcher'], group: 'foo')).to eq guard_rspec
      end
    end
  end

  describe '#plugin_location' do
    context 'Rubygems < 1.8.0' do
      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        expect(Gem::Version).to receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        gems_source_index = double
        gems_found = [double(full_gem_path: 'gems/guard-rspec')]
        expect(Gem).to receive(:source_index) { gems_source_index }
        expect(gems_source_index).to receive(:find_name).with('guard-rspec') { gems_found }

        expect(described_class.new('rspec').plugin_location).to eq 'gems/guard-rspec'
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        expect(Gem::Version).to receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        expect(Gem::Specification).to receive(:find_by_name).with('guard-rspec') { double(full_gem_path: 'gems/guard-rspec') }

        expect(described_class.new('rspec').plugin_location).to eq 'gems/guard-rspec'
      end
    end
  end

  describe '#plugin_class' do
    after do
      [:Classname, :DashedClassName, :UnderscoreClassName, :VSpec, :Inline].each do |const|
        Guard.send(:remove_const, const) rescue nil
      end
    end

    it "reports an error if the class is not found" do
      expect(::Guard::UI).to receive(:error).twice
      described_class.new('notAGuardClass').plugin_class
    end

    context 'with a nested Guard class' do
      it "resolves the Guard class from string" do
        plugin = described_class.new('classname')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/classname'
          class Guard::Classname;
          end
        end
        expect(plugin.plugin_class).to eq Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        plugin = described_class.new(:classname)
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/classname'
          class Guard::Classname;
          end
        end
        expect(plugin.plugin_class).to eq Guard::Classname
      end
    end

    context 'with a name with dashes' do
      it "returns the Guard class" do
        plugin = described_class.new('dashed-class-name')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/dashed-class-name'
          class Guard::DashedClassName;
          end
        end
        expect(plugin.plugin_class).to eq Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      it "returns the Guard class" do
        plugin = described_class.new('underscore_class_name')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName;
          end
        end
        expect(plugin.plugin_class).to eq Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      it "returns the Guard class" do
        plugin = described_class.new('vspec')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/vspec'
          class Guard::VSpec;
          end
        end
        expect(plugin.plugin_class).to eq Guard::VSpec
      end
    end

    context 'with an inline Guard class' do
      it 'returns the Guard class' do
        plugin = described_class.new('inline')
        module Guard
          class Inline < Guard
          end
        end

        expect(plugin).to_not receive(:require)
        expect(plugin.plugin_class).to eq Guard::Inline
      end
    end

    context 'when set to fail gracefully' do
      it 'does not print error messages on fail' do
        expect(::Guard::UI).to_not receive(:error)
        expect(described_class.new('notAGuardClass').plugin_class(fail_gracefully: true)).to be_nil
      end
    end
  end

  describe '#add_to_guardfile' do
    before do
      ::Guard.stub(:evaluator) { guardfile_evaluator }
    end

    context 'when the Guard is already in the Guardfile' do
      before do
        guardfile_evaluator.stub(:guardfile_include?).and_return(true)
      end

      it 'shows an info message' do
        expect(::Guard::UI).to receive(:info).with 'Guardfile already includes myguard guard'

        described_class.new('myguard').add_to_guardfile
      end
    end

    context 'when the Guard is not in the Guardfile' do
      let(:plugin_util) { described_class.new('myguard') }
      before do
        stub_const 'Guard::Myguard', Class.new(Guard::Plugin)
        plugin_util.stub(:plugin_class) { Guard::Myguard }
        expect(plugin_util).to receive(:plugin_location) { '/Users/me/projects/guard-myguard' }
        guardfile_evaluator.stub(:guardfile_include?).and_return(false)
      end

      it 'appends the template to the Guardfile' do
        expect(File).to receive(:read).with('Guardfile') { 'Guardfile content' }
        expect(File).to receive(:read).with('/Users/me/projects/guard-myguard/lib/guard/myguard/templates/Guardfile') { 'Template content' }
        io = StringIO.new
        expect(File).to receive(:open).with('Guardfile', 'wb').and_yield io

        plugin_util.add_to_guardfile

        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end
  end

end
