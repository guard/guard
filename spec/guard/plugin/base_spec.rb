require 'spec_helper'
require 'guard/plugin'

describe Guard::Plugin::Base do
  before do
    stub_const 'Guard::Dummy', Class.new(Guard::Plugin)
  end

  describe '.template' do
    before do
      File.stub(:read)
    end

    it 'reads the default template' do
      File.should_receive(:read).with('/guard-dummy/lib/guard/dummy/templates/Guardfile') { true }

      Guard::Dummy.template('/guard-dummy')
    end
  end

  describe '#name' do
    it 'outputs the short plugin name' do
      Guard::Dummy.new.name.should eq 'dummy'
    end
  end

  describe '#title' do
    it 'outputs the plugin title' do
      Guard::Dummy.new.title.should eq 'Dummy'
    end
  end

  describe '#to_s' do
    it 'output the short plugin name' do
      Guard::Dummy.new.to_s.should eq '#<Guard::Dummy @name=dummy @group=#<Guard::Group @name=default @options={}> @watchers=[] @callbacks=[] @options={}>'
    end
  end

end