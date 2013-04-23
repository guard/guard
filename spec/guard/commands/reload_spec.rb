require 'spec_helper'
require 'guard/plugin'

describe 'Guard::Interactor::RELOAD' do

  let(:guard)     { ::Guard.setup }
  let(:foo_group) { guard.add_group(:foo) }
  let(:bar_guard) { guard.add_guard(:bar, :group => :foo) }

  before do
    Guard.stub(:reload)
    Guard.stub(:setup_interactor)
    Pry.output.stub(:puts)
    stub_const 'Guard::Bar', Class.new(Guard::Plugin)
  end

  describe '#perform' do
    context 'without scope' do
      it 'runs the :reload action' do
        Guard.should_receive(:reload).with({ :groups => [], :plugins => [] })
        Pry.run_command 'reload'
      end
    end

    context 'with a valid Guard group scope' do
      it 'runs the :reload action with the given scope' do
        Guard.should_receive(:reload).with({ :groups => [foo_group], :plugins => [] })
        Pry.run_command 'reload foo'
      end
    end

    context 'with a valid Guard plugin scope' do
      it 'runs the :reload action with the given scope' do
        Guard.should_receive(:reload).with({ :plugins => [bar_guard], :groups => [] })
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
