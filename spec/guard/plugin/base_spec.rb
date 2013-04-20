require 'spec_helper'

describe Guard::Plugin::Base do

  describe '#name' do
    before do
      class Guard::Dummy < Guard::Plugin; end
    end

    it 'outputs the short plugin name' do
      Guard::Dummy.new.name.should eq 'dummy'
    end
  end

  describe '#title' do
    before do
      class Guard::Dummy < Guard::Plugin; end
    end

    it 'outputs the plugin title' do
      Guard::Dummy.new.title.should eq 'Dummy'
    end
  end

  describe '#to_s' do
    before do
      class Guard::Dummy < Guard::Plugin; end
    end

    it 'output the short plugin name' do
      Guard::Dummy.new.to_s.should eq '#<Guard::Dummy @name=dummy @group=#<Guard::Group @name=default @options={}> @watchers=[] @callbacks=[] @options={}>'
    end
  end

end