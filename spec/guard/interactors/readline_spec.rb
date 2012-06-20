require 'spec_helper'
require 'guard/interactors/readline'
require 'readline'

describe Guard::ReadlineInteractor do
  subject { Guard::ReadlineInteractor.new }

  describe "#initialize" do
    # completion_proc getter is not implemented in JRuby
    # see https://github.com/jruby/jruby/blob/master/src/org/jruby/ext/Readline.java#L349
    if RUBY_PLATFORM != 'java'
      it 'sets the Readline completion proc' do
        subject
        Readline.completion_proc.should be_a Proc
      end
    end
  end

  describe '#readline' do   
    before do
      Guard.listener = mock('listener')
      Guard.listener.stub(:paused?).and_return false
    end

    it 'reads all lines for processing' do
      Readline.should_receive(:readline).and_return 'First line'
      Readline.should_receive(:readline).and_return 'Second line'
      Readline.should_receive(:readline).and_return "\x00 \tControl line"
      Readline.should_receive(:readline).and_return nil
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
    
    it 'returns > when listener is active' do
      ::Guard.listener.should_receive(:paused?).and_return false
      subject.prompt.should == '> '
    end

    it 'returns p> when listener is paused' do
      ::Guard.listener.should_receive(:paused?).and_return true
      subject.prompt.should == 'p> '
    end
  end

end
