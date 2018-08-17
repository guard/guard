# frozen_string_literal: true

require 'guard/plugin_util'

require 'guard/guardfile/evaluator'

RSpec.describe Guard::PluginUtil do
  let(:guard_rspec_class) { class_double('Guard::Plugin') }
  let(:guard_rspec) { instance_double('Guard::Plugin') }
  let(:evaluator) { instance_double('Guard::Guardfile::Evaluator') }
  let(:session) { instance_double('Guard::Internals::Session') }
  let(:state) { instance_double('Guard::Internals::State') }

  before do
    allow(session).to receive(:evaluator_options).and_return({})
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)
    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
  end

  describe '.plugin_names' do
    before do
      spec = Gem::Specification
      gems = [
        instance_double(spec, name: 'guard-myplugin'),
        instance_double(spec, name: 'gem1', full_gem_path: '/gem1'),
        instance_double(spec, name: 'gem2', full_gem_path: '/gem2'),
        instance_double(spec, name: 'guard-compat'),
      ]
      allow(File).to receive(:exist?)
        .with('/gem1/lib/guard/gem1.rb') { false }

      allow(File).to receive(:exist?)
        .with('/gem2/lib/guard/gem2.rb') { true }

      gem = class_double(Gem::Specification)
      stub_const('Gem::Specification', gem)
      expect(Gem::Specification).to receive(:find_all) { gems }
      allow(Gem::Specification).to receive(:unresolved_deps) { [] }
    end

    it 'returns the list of guard gems' do
      expect(described_class.plugin_names).to include('myplugin')
    end

    it 'returns the list of embedded guard gems' do
      expect(described_class.plugin_names).to include('gem2')
    end

    it 'ignores guard-compat' do
      expect(described_class.plugin_names).to_not include('compat')
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
      allow_any_instance_of(described_class)
        .to receive(:plugin_class)
        .and_return(guard_rspec_class)
    end

    context 'with a plugin inheriting from Guard::Plugin' do
      before do
        expect(guard_rspec_class).to receive(:ancestors) { [::Guard::Plugin] }
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

    it 'returns the path of a Guard gem' do
      expect(Gem::Specification).to receive(:find_by_name)
        .with('guard-rspec') { double(full_gem_path: 'gems/guard-rspec') }
      expect(subject.plugin_location).to eq 'gems/guard-rspec'
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
      expect(::Guard::UI).to receive(:error).with(/Could not load/)
      expect(::Guard::UI).to receive(:error).with(/Error is: cannot load/)
      expect(::Guard::UI).to receive(:error).with(/plugin_util.rb/)

      plugin = described_class.new('notAGuardClass')
      allow(plugin).to receive(:require).with('guard/notaguardclass')
        .and_raise(LoadError, 'cannot load such file --')

      plugin.plugin_class
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
        mod = nil
        allow(plugin).to receive(:require) do |classname|
          expect(classname).to eq 'guard/vspec'
          module Guard
            class VSpec
            end
          end
          mod = Guard::VSpec
        end
        expect(plugin.plugin_class).to eq mod
        expect(mod).to be
      end
    end

    context 'with an inline Guard class' do
      subject { described_class.new('inline') }
      let(:plugin_class) { class_double('Guard::Plugin') }

      it 'returns the Guard class' do
        allow(Guard).to receive(:constants).and_return([:Inline])
        allow(Guard).to receive(:const_get).with(:Inline)
          .and_return(plugin_class)

        expect(subject).to_not receive(:require)
        expect(subject.plugin_class).to eq plugin_class
      end
    end

    context 'when set to fail gracefully' do
      options = { fail_gracefully: true }
      subject { described_class.new('notAGuardClass') }
      it 'does not print error messages on fail' do
        expect(::Guard::UI).to_not receive(:error)
        plugin = subject
        allow(plugin).to receive(:require).and_raise(LoadError)
        expect(subject.plugin_class(options)).to be_nil
      end
    end
  end

  describe '#add_to_guardfile' do
    before do
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
      allow(evaluator).to receive(:evaluate)
    end

    context 'when the Guard is already in the Guardfile' do
      before do
        allow(evaluator).to receive(:guardfile_include?) { true }
      end

      it 'shows an info message' do
        expect(::Guard::UI).to receive(:info)
          .with 'Guardfile already includes myguard guard'

        described_class.new('myguard').add_to_guardfile
      end
    end

    context 'when Guardfile is empty' do
      let(:plugin_util) { described_class.new('myguard') }
      let(:plugin_class) { class_double('Guard::Plugin') }
      let(:location) { '/Users/me/projects/guard-myguard' }
      let(:gem_spec) { instance_double('Gem::Specification') }
      let(:io) { StringIO.new }

      before do
        allow(evaluator).to receive(:evaluate)
          .and_raise(Guard::Guardfile::Evaluator::NoPluginsError)

        allow(gem_spec).to receive(:full_gem_path).and_return(location)
        allow(evaluator).to receive(:guardfile_include?) { false }
        allow(Guard).to receive(:constants).and_return([:MyGuard])
        allow(Guard).to receive(:const_get).with(:MyGuard)
          .and_return(plugin_class)

        allow(Gem::Specification).to receive(:find_by_name)
          .with('guard-myguard').and_return(gem_spec)

        allow(plugin_class).to receive(:template).with(location)
          .and_return('Template content')

        allow(File).to receive(:read).with('Guardfile') { 'Guardfile content' }
        allow(File).to receive(:open).with('Guardfile', 'wb').and_yield io
      end

      it 'appends the template to the Guardfile' do
        plugin_util.add_to_guardfile
        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end

    context 'when the Guard is not in the Guardfile' do
      let(:plugin_util) { described_class.new('myguard') }
      let(:plugin_class) { class_double('Guard::Plugin') }
      let(:location) { '/Users/me/projects/guard-myguard' }
      let(:gem_spec) { instance_double('Gem::Specification') }
      let(:io) { StringIO.new }

      before do
        allow(gem_spec).to receive(:full_gem_path).and_return(location)
        allow(evaluator).to receive(:guardfile_include?) { false }
        allow(Guard).to receive(:constants).and_return([:MyGuard])
        allow(Guard).to receive(:const_get).with(:MyGuard)
          .and_return(plugin_class)

        allow(Gem::Specification).to receive(:find_by_name)
          .with('guard-myguard').and_return(gem_spec)

        allow(plugin_class).to receive(:template).with(location)
          .and_return('Template content')

        allow(File).to receive(:read).with('Guardfile') { 'Guardfile content' }
        allow(File).to receive(:open).with('Guardfile', 'wb').and_yield io
      end

      it 'appends the template to the Guardfile' do
        plugin_util.add_to_guardfile
        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end
  end
end
