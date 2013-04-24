require 'spec_helper'
require 'guard/plugin'

describe Guard::PluginUtil do

  let!(:rubygems_version_1_7_2) { Gem::Version.create('1.7.2') }
  let!(:rubygems_version_1_8_0) { Gem::Version.create('1.8.0') }
  let(:guard_rspec_class) { double('Guard::RSpec') }
  let(:guard_rspec) { double('Guard::RSpec instance') }

  describe '.plugin_names' do
    context 'Rubygems < 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems_source_index = stub
        Gem.should_receive(:source_index) { gems_source_index }
        gems_source_index.should_receive(:find_name).with(/^guard-/) { [stub(:name => 'guard-rspec')] }
      end

      it 'returns the list of guard gems' do
        described_class.plugin_names.should include('rspec')
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems = [
          stub(:name => 'guard'),
          stub(:name => 'guard-rspec'),
          stub(:name => 'gem1', :full_gem_path => '/gem1'),
          stub(:name => 'gem2', :full_gem_path => '/gem2'),
        ]
        File.stub(:exists?).with('/gem1/lib/guard/gem1.rb') { false }
        File.stub(:exists?).with('/gem2/lib/guard/gem2.rb') { true }
        Gem::Specification.should_receive(:find_all) { gems }
      end

      it "returns the list of guard gems" do
        described_class.plugin_names.should include('rspec')
      end

      it "returns the list of embedded guard gems" do
        described_class.plugin_names.should include('gem2')
      end
    end
  end

  describe '#initialize_plugin' do
    let(:plugin_util) { described_class.new('rspec') }

    before do
      described_class.any_instance.stub(:plugin_class).and_return(guard_rspec_class)
    end

    context 'with a plugin inheriting from Guard::Guard (deprecated)' do
      before { guard_rspec_class.should_receive(:superclass) { ::Guard::Guard } }

      it 'instantiate the plugin using the old API' do
        guard_rspec_class.should_receive(:new).with(['watcher'], :group => 'foo').and_return(guard_rspec)

        plugin_util.initialize_plugin(:watchers => ['watcher'], :group => 'foo').should eq guard_rspec
      end
    end

    context 'with a plugin inheriting from Guard::Plugin' do
      before { guard_rspec_class.should_receive(:superclass) { ::Guard::Plugin } }

      it 'instantiate the plugin using the new API' do
        guard_rspec_class.should_receive(:new).with(:watchers => ['watcher'], :group => 'foo').and_return(guard_rspec)

        plugin_util.initialize_plugin(:watchers => ['watcher'], :group => 'foo').should eq guard_rspec
      end
    end
  end

  describe '#plugin_location' do
    context 'Rubygems < 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        gems_source_index = stub
        gems_found = [stub(:full_gem_path => 'gems/guard-rspec')]
        Gem.should_receive(:source_index) { gems_source_index }
        gems_source_index.should_receive(:find_name).with('guard-rspec') { gems_found }

        described_class.new('rspec').plugin_location.should eq 'gems/guard-rspec'
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        Gem::Specification.should_receive(:find_by_name).with('guard-rspec') { stub(:full_gem_path => 'gems/guard-rspec') }

        described_class.new('rspec').plugin_location.should eq 'gems/guard-rspec'
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
      ::Guard::UI.should_receive(:error).twice
      described_class.new('notAGuardClass').plugin_class
    end

    context 'with a nested Guard class' do
      it "resolves the Guard class from string" do
        plugin = described_class.new('classname')
        plugin.should_receive(:require) do |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        end
        plugin.plugin_class.should eq Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        plugin = described_class.new(:classname)
        plugin.should_receive(:require) do |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        end
        plugin.plugin_class.should eq Guard::Classname
      end
    end

    context 'with a name with dashes' do
      it "returns the Guard class" do
        plugin = described_class.new('dashed-class-name')
        plugin.should_receive(:require) do |classname|
          classname.should eq 'guard/dashed-class-name'
          class Guard::DashedClassName;
          end
        end
        plugin.plugin_class.should eq Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      it "returns the Guard class" do
        plugin = described_class.new('underscore_class_name')
        plugin.should_receive(:require) do |classname|
          classname.should eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName;
          end
        end
        plugin.plugin_class.should eq Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      it "returns the Guard class" do
        plugin = described_class.new('vspec')
        plugin.should_receive(:require) do |classname|
          classname.should eq 'guard/vspec'
          class Guard::VSpec;
          end
        end
        plugin.plugin_class.should eq Guard::VSpec
      end
    end

    context 'with an inline Guard class' do
      it 'returns the Guard class' do
        plugin = described_class.new('inline')
        module Guard
          class Inline < Guard
          end
        end

        plugin.should_not_receive(:require)
        plugin.plugin_class.should eq Guard::Inline
      end
    end

    context 'when set to fail gracefully' do
      it 'does not print error messages on fail' do
        ::Guard::UI.should_not_receive(:error)
        described_class.new('notAGuardClass').plugin_class(:fail_gracefully => true).should be_nil
      end
    end
  end

  describe '#add_to_guardfile' do
    context 'when the Guard is already in the Guardfile' do
      before { ::Guard::Dsl.stub(:guardfile_include?).and_return true }

      it 'shows an info message' do
        ::Guard::UI.should_receive(:info).with 'Guardfile already includes myguard guard'

        described_class.new('myguard').add_to_guardfile
      end
    end

    context 'when the Guard is not in the Guardfile' do
      let(:plugin_util) { described_class.new('myguard') }
      before do
        stub_const 'Guard::Myguard', Class.new(Guard::Plugin)
        plugin_util.stub(:plugin_class) { Guard::Myguard }
        plugin_util.should_receive(:plugin_location) { '/Users/me/projects/guard-myguard' }
        ::Guard::Dsl.stub(:guardfile_include?).and_return(false)
      end

      it 'appends the template to the Guardfile' do
        File.should_receive(:read).with('Guardfile') { 'Guardfile content' }
        File.should_receive(:read).with('/Users/me/projects/guard-myguard/lib/guard/myguard/templates/Guardfile') { 'Template content' }
        io = StringIO.new
        File.should_receive(:open).with('Guardfile', 'wb').and_yield io

        plugin_util.add_to_guardfile

        io.string.should eq "Guardfile content\n\nTemplate content\n"
      end
    end
  end

end