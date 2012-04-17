require 'spec_helper'
require 'guard/interactors/readline'

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

  describe '#start' do
    context 'when running on a system that has stty' do
      before { subject.should_receive(:stty_exists?).and_return(true) }

      it 'stores the terminal settings' do
        subject.should_receive(:store_terminal_settings)
        subject.start
      end
    end

    context 'when running on a system without stty' do
      before { subject.should_receive(:stty_exists?).and_return(false) }

      it 'does not store the terminal settings' do
        subject.should_not_receive(:store_terminal_settings)
        subject.start
      end
    end
  end

  describe '#stop' do
    before { subject.instance_variable_set(:@thread, Thread.current) }

    context 'when running on a system that has stty' do
      before { subject.should_receive(:stty_exists?).and_return(true) }

      it 'restores the terminal settings' do
        subject.should_receive(:restore_terminal_settings)
        subject.stop
      end
    end

    context 'when running on a system without stty' do
      before { subject.should_receive(:stty_exists?).and_return(false) }

      it 'does not store the terminal settings' do
        subject.should_not_receive(:restore_terminal_settings)
        subject.stop
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

  describe '#auto_complete' do
    it 'returns the matching list of words' do
      subject.should_receive(:completion_list).any_number_of_times.and_return %w[help reload exit pause notification backend frontend foo foobar]
      subject.auto_complete('f').should =~ ['frontend', 'foo', 'foobar']
      subject.auto_complete('foo').should =~ ['foo', 'foobar']
      subject.auto_complete('he').should =~ ['help']
      subject.auto_complete('re').should =~ ['reload']
    end
  end

  describe "#completion_list" do
    before(:all) do
      class Guard::Foo < Guard::Guard; end
      class Guard::FooBar < Guard::Guard; end
    end

    before(:each) do
      guard = ::Guard
      guard.setup_guards
      guard.setup_groups
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_bar_guard  = guard.add_guard('foo-bar', [], [], { :group => :frontend })
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:Foo)
        remove_const(:FooBar)
      end
    end

    it 'creates the list of string to auto complete' do
      subject.completion_list.should =~ %w[help reload exit pause notification backend frontend foo foobar]
    end

    it 'does not include the default scope' do
      subject.completion_list.should_not include('default')
    end
  end

  describe "#prompt" do
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
