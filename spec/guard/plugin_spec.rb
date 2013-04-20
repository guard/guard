require 'spec_helper'

describe Guard::Plugin do

  describe '#initialize' do
    it 'assigns the defined watchers' do
      watchers = [Guard::Watcher.new('*')]
      Guard::Plugin.new(:watchers => watchers).watchers.should eq watchers
    end

    it 'assigns the defined options' do
      options = { :a => 1, :b => 2 }
      Guard::Plugin.new(options).options.should eq options
    end

    context 'with a group in the options' do
      it 'assigns the given group' do
        Guard::Plugin.new(:group => :test).group.should eq Guard.groups(:test)
      end
    end

    context 'without a group in the options' do
      it 'assigns a default group' do
        Guard::Plugin.new.group.should eq Guard.groups(:default)
      end
    end
  end

end
