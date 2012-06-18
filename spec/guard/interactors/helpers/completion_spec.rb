require 'spec_helper'
require 'guard/interactors/helpers/completion'

describe Guard::CompletionHelper do
  subject do
    Class.new(::Guard::Interactor) { include Guard::CompletionHelper }.new
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
      subject.completion_list.should =~ %w[help reload exit pause notification backend frontend foo foobar show]
    end

    it 'does not include the default scope' do
      subject.completion_list.should_not include('default')
    end
  end
end