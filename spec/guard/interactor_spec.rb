require 'spec_helper'
require 'guard/guard'

describe Guard::Interactor do
  subject { Guard::Interactor.new }

  describe "#initialize" do
    it 'configures the thread to abort on exception' do
      subject
      Thread.abort_on_exception.should be_true
    end

    it 'sets the Readline append character' do
      subject
      Readline.completion_append_character.should eql ' '
    end

    it 'sets the Readline completion proc' do
      subject
      Readline.completion_proc.should be_a Proc
    end
  end

  describe "#update_completion_list" do
    class Guard::Foo < Guard::Guard; end
    class Guard::FooBar < Guard::Guard; end

    before(:each) do
      guard = ::Guard.setup
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_bar_guard  = guard.add_guard('foo-bar', [], [], { :group => :frontend })
    end

    it 'creates the list of string to auto complete' do
      subject.completion_list.should =~ %w[help reload exit pause notification backend frontend foo foobar]
    end
  end

  describe "#prompt" do
    it 'returns > when listener is active' do
      ::Guard.listener.should_receive(:paused?).and_return false
      subject.prompt.should eql '> '
    end

    it 'returns p> when listener is paused' do
      ::Guard.listener.should_receive(:paused?).and_return true
      subject.prompt.should eql 'p> '
    end
  end

  describe "#extract_scopes_and_action" do

    class Guard::Foo < Guard::Guard; end
    class Guard::FooBar < Guard::Guard; end

    before(:each) do
      guard = ::Guard.setup
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_bar_guard  = guard.add_guard('foo-bar', [], [], { :group => :frontend })
    end

    it "returns :run_all action if entry is blank" do
      subject.extract_scopes_and_action('').should eql([{}, :run_all])
    end

    it "returns action if entry is only a action" do
      subject.extract_scopes_and_action('exit').should eql([{}, :stop])
    end

    it "returns guard scope and run_all action if entry is only a guard scope" do
      subject.extract_scopes_and_action('foo-bar').should eql([{ :guard => @foo_bar_guard }, :run_all])
    end

    it "returns group scope and run_all action if entry is only a group scope" do
      subject.extract_scopes_and_action('backend').should eql([{ :group => @backend_group }, :run_all])
    end

    it "returns no action if entry is not a scope or action" do
      subject.extract_scopes_and_action('x').should eql([{}, nil])
    end

    it "returns guard scope and action if entry is a guard scope and a action" do
      subject.extract_scopes_and_action('foo r').should eql([{ :guard => @foo_guard }, :reload])
    end

    it "returns group scope and action if entry is a group scope and a action" do
      subject.extract_scopes_and_action('frontend r').should eql([{ :group => @frontend_group }, :reload])
    end

    it "returns group scope and run_all action if entry is a group scope and not a action" do
      subject.extract_scopes_and_action('frontend x').should eql([{ :group => @frontend_group }, :run_all])
    end

    it "returns no action if entry is not a scope and not a action" do
      subject.extract_scopes_and_action('x x').should eql([{}, nil])
    end

  end

end
