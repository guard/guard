require 'spec_helper'

describe 'Guard::Interactor::RELOAD' do

  before(:all) { class ::Guard::Bar < ::Guard::Guard; end }
  after(:all)  { ::Guard.instance_eval { remove_const(:Bar) } }

  before(:each) do
    Guard.stub(:reload)
    Guard.stub(:setup_interactor)
  end

  let(:guard)     { ::Guard.setup }
  let(:foo_group) { guard.add_group(:foo) }
  let(:bar_guard) { guard.add_guard(:bar, [], [], { :group => :foo }) }

  describe '#perform' do
    context 'without scope' do
      it 'runs the :reload action' do
        Guard.should_receive(:reload).with({})
        Pry.run_command 'reload'
      end
    end

    context 'with a valid Guard group scope' do
      it 'runs the :reload action with the given scope' do
        Guard.should_receive(:reload).with({ :group => foo_group })
        Pry.run_command 'reload foo'
      end
    end

    context 'with a valid Guard plugin scope' do
      it 'runs the :reload action with the given scope' do
        Guard.should_receive(:reload).with({ :guard => bar_guard })
        Pry.run_command 'reload bar'
      end
    end

    context 'with an invalid scope' do
      it 'does not run the action' do
        Guard.should_not_receive(:reload)
        Pry.run_command 'reload baz'
      end
    end
  end
end