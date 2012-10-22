require 'spec_helper'

describe 'Guard::Interactor::ALL' do

  before(:all) { class ::Guard::Bar < ::Guard::Guard; end }
  after(:all)  { ::Guard.instance_eval { remove_const(:Bar) } }

  before(:each) do
    Guard.stub(:run_all)
    Guard.stub(:setup_interactor)
    Pry.output.stub(:puts)
  end

  let(:guard)     { ::Guard.setup }
  let(:foo_group) { guard.add_group(:foo) }
  let(:bar_guard) { guard.add_guard(:bar, [], [], { :group => :foo }) }

  describe '#perform' do
    context 'without scope' do
      it 'runs the :run_all action' do
        Guard.should_receive(:run_all).with({})
        Pry.run_command 'all'
      end
    end

    context 'with a valid Guard group scope' do
      it 'runs the :run_all action with the given scope' do
        Guard.should_receive(:run_all).with({ :group => foo_group })
        Pry.run_command 'all foo'
      end
    end

    context 'with a valid Guard plugin scope' do
      it 'runs the :run_all action with the given scope' do
        Guard.should_receive(:run_all).with({ :guard => bar_guard })
        Pry.run_command 'all bar'
      end
    end

    context 'with an invalid scope' do
      it 'does not run the action' do
        Guard.should_not_receive(:run_all)
        Pry.run_command 'all baz'
      end
    end
  end
end
