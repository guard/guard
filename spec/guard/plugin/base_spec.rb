require 'spec_helper'
require 'guard/plugin'

describe Guard::Plugin::Base do
  before do
    stub_const 'Guard::DuMmy', Class.new(Guard::Plugin)
  end

  describe '.non_namespaced_classname' do
    it 'remove the Guard:: namespace' do
      Guard::DuMmy.non_namespaced_classname.should eq 'DuMmy'
    end
  end

  describe '.non_namespaced_name' do
    it 'remove the Guard:: namespace and downcase' do
      Guard::DuMmy.non_namespaced_name.should eq 'dummy'
    end
  end

  describe '.template' do
    before do
      File.stub(:read)
    end

    it 'reads the default template' do
      File.should_receive(:read).with('/guard-dummy/lib/guard/dummy/templates/Guardfile') { true }

      Guard::DuMmy.template('/guard-dummy')
    end
  end

  describe '#name' do
    it 'outputs the short plugin name' do
      Guard::DuMmy.new.name.should eq 'dummy'
    end
  end

  describe '#title' do
    it 'outputs the plugin title' do
      Guard::DuMmy.new.title.should eq 'DuMmy'
    end
  end

  describe '#to_s' do
    it 'output the short plugin name' do
      Guard::DuMmy.new.to_s.should eq '#<Guard::DuMmy @name=dummy @group=#<Guard::Group @name=default @options={}> @watchers=[] @callbacks=[] @options={}>'
    end
  end

end
