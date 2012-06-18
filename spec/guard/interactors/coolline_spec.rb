require 'spec_helper'
require 'guard/interactors/readline'

describe Guard::CoollineInteractor do
  subject { Guard::CoollineInteractor.new }

  describe '#readline' do
    let(:coolline) { mock('coolline') }

    before do
      class Coolline
      end
      ::Coolline.stub(:new) { coolline }
    end
    
    before do
      Guard.listener = mock('listener')
      Guard.listener.stub(:paused?).and_return false  
    end
 
    it 'reads all lines for processing' do
      coolline.should_receive(:readline).and_return 'First line'
      coolline.should_receive(:readline).and_return 'Second line'
      coolline.should_receive(:readline).and_return 'Control line'
      coolline.should_receive(:readline).and_return nil
      subject.should_receive(:process_input).with('First line').and_return
      subject.should_receive(:process_input).with('Second line').and_return
      subject.should_receive(:process_input).with('Control line').and_return
      subject.read_line
    end
  end

  describe "#prompt" do
    before do
      ::Guard.listener = stub('Listener')
    end
    
    it 'returns >> when listener is active' do
      ::Guard.listener.should_receive(:paused?).and_return false
      subject.prompt.should == '>> '
    end

    it 'returns p> when listener is paused' do
      ::Guard.listener.should_receive(:paused?).and_return true
      subject.prompt.should == 'p> '
    end
  end

end
