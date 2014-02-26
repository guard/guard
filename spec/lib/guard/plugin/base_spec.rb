require 'spec_helper'
require 'guard/plugin'

describe Guard::Plugin::Base do
  before do
    stub_const 'Guard::DuMmy', Class.new(Guard::Plugin)
  end

  describe '.non_namespaced_classname' do
    it 'remove the Guard:: namespace' do
      expect(Guard::DuMmy.non_namespaced_classname).to eq 'DuMmy'
    end
  end

  describe '.non_namespaced_name' do
    it 'remove the Guard:: namespace and downcase' do
      expect(Guard::DuMmy.non_namespaced_name).to eq 'dummy'
    end
  end

  describe '.template' do
    before do
      allow(File).to receive(:read)
    end

    it 'reads the default template' do
      expect(File).to receive(:read).with('/guard-dummy/lib/guard/dummy/templates/Guardfile') { true }

      Guard::DuMmy.template('/guard-dummy')
    end
  end

  describe '#name' do
    it 'outputs the short plugin name' do
      expect(Guard::DuMmy.new.name).to eq 'dummy'
    end
  end

  describe '#title' do
    it 'outputs the plugin title' do
      expect(Guard::DuMmy.new.title).to eq 'DuMmy'
    end
  end

  describe '#to_s' do
    it 'output the short plugin name' do
      expect(Guard::DuMmy.new.to_s).to eq '#<Guard::DuMmy @name=dummy @group=#<Guard::Group @name=default @options={}> @watchers=[] @callbacks=[] @options={}>'
    end
  end

end
