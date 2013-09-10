require 'spec_helper'
require 'guard/guard'

describe Guard::Guard do

  describe '#initialize' do
    it 'assigns the defined watchers' do
      watchers = [Guard::Watcher.new('*')]
      Guard::Guard.new(watchers).watchers.should eq watchers
    end

    it 'assigns the defined options' do
      options = { a: 1, b: 2 }
      Guard::Guard.new([], options).options.should eq options
    end

    context 'with a group in the options' do
      it 'assigns the given group' do
        Guard::Guard.new([], group: :test).group.should eq Guard.group(:test)
      end
    end

    context 'without a group in the options' do
      it 'assigns a default group' do
        Guard::Guard.new.group.should eq Guard.group(:default)
      end
    end
  end

end
