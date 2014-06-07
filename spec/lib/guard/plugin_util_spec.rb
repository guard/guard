require 'spec_helper'

require 'guard/plugin'

# Needed for a test below
module Guard
  class Guard
  end
end

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
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) do
          rubygems_version_1_7_2
        end

        expect(Gem::Version).to receive(:create).with('1.8.0') do
          rubygems_version_1_8_0
        end

        gems_source_index = double
        expect(Gem).to receive(:source_index) { gems_source_index }
        expect(gems_source_index).to receive(:find_name).with(/^guard-/) do
          [double(name: 'guard-rspec'), double(name: 'guard-rspec')]
        end
      end

      it 'returns the list of guard gems' do
        expect(described_class.plugin_names).to eq ['rspec']
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) do
          rubygems_version_1_8_0
        end

        expect(Gem::Version).to receive(:create).with('1.8.0') do
          rubygems_version_1_8_0
        end

        gems = [
          double(name: 'guard'),
          double(name: 'guard-rspec'),
          double(name: 'gem1', full_gem_path: '/gem1'),
          double(name: 'gem2', full_gem_path: '/gem2'),
        ]
        allow(File).to receive(:exist?).
          with('/gem1/lib/guard/gem1.rb') { false }

        allow(File).to receive(:exist?).
          with('/gem2/lib/guard/gem2.rb') { true }

        expect(Gem::Specification).to receive(:find_all) { gems }
      end

      it 'returns the list of guard gems' do
        expect(described_class.plugin_names).to include('rspec')
      end

      it 'returns the list of embedded guard gems' do
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
      allow_any_instance_of(described_class).
        to receive(:plugin_class).
        and_return(guard_rspec_class)
    end

    context 'with a plugin inheriting from Guard::Guard (deprecated)' do
      before do
        expect(guard_rspec_class).to receive(:superclass) { ::Guard::Guard }
      end

      it 'instantiate the plugin using the old API' do
        expect(guard_rspec_class).to receive(:new).
          with(['watcher'], group: 'foo') { guard_rspec }

        options = { watchers: ['watcher'], group: 'foo' }
        old_plugin = plugin_util.initialize_plugin(options)
        expect(old_plugin).to eq guard_rspec
      end
    end

    context 'with a plugin inheriting from Guard::Plugin' do
      before do
        expect(guard_rspec_class).to receive(:superclass) { ::Guard::Plugin }
      end

      it 'instantiate the plugin using the new API' do

        options = { watchers: ['watcher'], group: 'foo' }
        expect(guard_rspec_class).to receive(:new).with(options) { guard_rspec }

        expect(plugin_util.initialize_plugin(options)).to eq guard_rspec
      end
    end
  end

  describe '#plugin_location' do
    subject { described_class.new('rspec') }

    context 'Rubygems < 1.8.0' do

      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) do
          rubygems_version_1_7_2
        end

        expect(Gem::Version).to receive(:create).with('1.8.0') do
          rubygems_version_1_8_0
        end
      end

      it 'returns the path of a Guard gem' do
        gems_source_index = double
        gems_found = [double(full_gem_path: 'gems/guard-rspec')]
        expect(Gem).to receive(:source_index) { gems_source_index }

        expect(gems_source_index).to receive(:find_name).with('guard-rspec') do
          gems_found
        end

        expect(subject.plugin_location).to eq 'gems/guard-rspec'
      end
    end

    context 'Rubygems >= 1.8.0' do

      before do
        expect(Gem::Version).to receive(:create).with(Gem::VERSION) do
          rubygems_version_1_8_0
        end

        expect(Gem::Version).to receive(:create).with('1.8.0') do
          rubygems_version_1_8_0
        end
      end

      it 'returns the path of a Guard gem' do
        expect(Gem::Specification).to receive(:find_by_name).
          with('guard-rspec') { double(full_gem_path: 'gems/guard-rspec') }

        expect(subject.plugin_location).to eq 'gems/guard-rspec'
      end
    end
  end

  describe '#plugin_class' do
    after do
      # TODO: use RSpec's stub const
      consts = [:Classname,
                :DashedClassName,
                :UnderscoreClassName,
                :VSpec,
                :Inline]

      consts.each do |const|
        begin
          Guard.send(:remove_const, const)
        rescue NameError
        end
      end
    end

    it 'reports an error if the class is not found' do
      expect(::Guard::UI).to receive(:error).twice
      described_class.new('notAGuardClass').plugin_class
    end

    context 'with a nested Guard class' do
      it 'resolves the Guard class from string' do
        plugin = described_class.new('classname')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/classname'
          module Guard
            class Classname
            end
          end
        end
        expect(plugin.plugin_class).to eq Guard::Classname
      end

      it 'resolves the Guard class from symbol' do
        plugin = described_class.new(:classname)
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/classname'
          module Guard
            class Classname
            end
          end
        end
        expect(plugin.plugin_class).to eq Guard::Classname
      end
    end

    context 'with a name with dashes' do
      it 'returns the Guard class' do
        plugin = described_class.new('dashed-class-name')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/dashed-class-name'
          module Guard
            class DashedClassName
            end
          end
        end
        expect(plugin.plugin_class).to eq Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      it 'returns the Guard class' do
        plugin = described_class.new('underscore_class_name')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/underscore_class_name'
          module Guard
            class UnderscoreClassName
            end
          end
        end
        expect(plugin.plugin_class).to eq Guard::UnderscoreClassName
      end
    end

    context 'with a name like VSpec' do
      it 'returns the Guard class' do
        plugin = described_class.new('vspec')
        expect(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/vspec'
          module Guard
            class VSpec
            end
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
      options = { fail_gracefully: true }
      subject { described_class.new('notAGuardClass') }
      it 'does not print error messages on fail' do
        expect(::Guard::UI).to_not receive(:error)
        expect(subject.plugin_class(options)).to be_nil
      end
    end
  end

  describe '#add_to_guardfile' do
    before do
      allow(::Guard).to receive(:evaluator) { guardfile_evaluator }
    end

    context 'when the Guard is already in the Guardfile' do
      before do
        allow(guardfile_evaluator).to receive(:guardfile_include?) { true }
      end

      it 'shows an info message' do
        expect(::Guard::UI).to receive(:info).
          with 'Guardfile already includes myguard guard'

        described_class.new('myguard').add_to_guardfile
      end
    end

    context 'when the Guard is not in the Guardfile' do
      let(:plugin_util) { described_class.new('myguard') }

      let(:long_path_not_sure_why) do
        '/Users/me/projects/guard-myguard/lib'\
          '/guard/myguard/templates/Guardfile'
      end

      before do
        stub_const 'Guard::Myguard', Class.new(Guard::Plugin)
        allow(plugin_util).to receive(:plugin_class) { Guard::Myguard }

        expect(plugin_util).to receive(:plugin_location) do
          '/Users/me/projects/guard-myguard'
        end

        allow(guardfile_evaluator).to receive(:guardfile_include?) { false }
      end

      it 'appends the template to the Guardfile' do
        expect(File).to receive(:read).with('Guardfile') { 'Guardfile content' }

        expect(File).to receive(:read).
          with(long_path_not_sure_why) { 'Template content' }

        io = StringIO.new
        expect(File).to receive(:open).with('Guardfile', 'wb').and_yield io

        plugin_util.add_to_guardfile

        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end
  end
end
