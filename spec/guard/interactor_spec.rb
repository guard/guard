require 'spec_helper'

describe Guard::Interactor do
  subject { Guard::Interactor.new }

  before do
    ::Guard::UI.stub(:info)
    ::Guard::UI.stub(:warning)
    ::Guard::UI.stub(:error)
    ::Guard::UI.stub(:debug)
    ::Guard::UI.stub(:deprecation)
  end

  describe '#readline' do
    it 'must be implemented by a subclass' do
      expect { subject.read_line }.to raise_error(NotImplementedError)
    end
  end

  describe '.fabricate' do
    context 'with coolline available' do
      before { Guard::CoollineInteractor.stub(:available?).and_return true }

      it 'returns the Coolline interactor for a :coolline symbol' do
        Guard::Interactor.interactor = :coolline
        Guard::Interactor.fabricate.should be_an_instance_of(Guard::CoollineInteractor)
      end
    end

    context 'with coolline unavailable' do
      before { Guard::CoollineInteractor.stub(:available?).and_return false }

      it 'returns nil' do
        Guard::Interactor.interactor = :coolline
        Guard::Interactor.fabricate.should be_nil
      end
    end

    context 'with readline available' do
      before { Guard::ReadlineInteractor.stub(:available?).and_return true }

      it 'returns the Readline interactor for a :readline symbol' do
        Guard::Interactor.interactor = :readline
        Guard::Interactor.fabricate.should be_an_instance_of(Guard::ReadlineInteractor)
      end
    end

    context 'with readline unavailable' do
      before { Guard::ReadlineInteractor.stub(:available?).and_return false }

      it 'returns nil' do
        Guard::Interactor.interactor = :readline
        Guard::Interactor.fabricate.should be_nil
      end
    end

    it 'returns the Gets interactor for a :simple symbol' do
      Guard::Interactor.interactor = :simple
      Guard::Interactor.fabricate.should be_an_instance_of(Guard::SimpleInteractor)
    end

    it 'returns nil for an :off symbol' do
      Guard::Interactor.interactor = :off
      Guard::Interactor.fabricate.should be_nil
    end

    it 'auto detects the interactor when unspecified' do
      Guard::Interactor.interactor = nil
      Guard::Interactor.should_receive(:auto_detect)
      Guard::Interactor.fabricate
    end
  end

  describe '.auto_detect' do
    context 'when all interactors are available' do
      before do
        Guard::CoollineInteractor.stub(:available?).and_return true
        Guard::ReadlineInteractor.stub(:available?).and_return true
      end

      it 'chooses the coolline interactor ' do
        Guard::Interactor.auto_detect.should be_an_instance_of(Guard::CoollineInteractor)
      end
    end

    context 'when only the coolline interactor is unavailable available' do
      before do
        Guard::CoollineInteractor.stub(:available?).and_return false
        Guard::ReadlineInteractor.stub(:available?).and_return true
      end

      it 'chooses the readline interactor ' do
        Guard::Interactor.auto_detect.should be_an_instance_of(Guard::ReadlineInteractor)
      end
    end

    context 'when coolline and readline interactors are unavailable available' do
      before do
        Guard::CoollineInteractor.stub(:available?).and_return false
        Guard::ReadlineInteractor.stub(:available?).and_return false
      end

      it 'chooses the simple interactor ' do
        Guard::Interactor.auto_detect.should be_an_instance_of(Guard::SimpleInteractor)
      end
    end
  end

  describe '#process_input' do
    before do
      ::Guard.stub(:within_preserved_state).and_yield
      ::Guard.runner = stub('runner')
    end

    it 'shows the help on help action' do
      subject.should_receive(:extract_scopes_and_action).with('help').and_return [{ }, :help, []]
      subject.should_receive(:help)
      subject.process_input 'help'
    end

    it 'describes the DSL on show action' do
      subject.should_receive(:extract_scopes_and_action).with('show').and_return [{ }, :show, []]
      ::Guard::DslDescriber.should_receive(:show)
      subject.process_input 'show'
    end

    it 'stops Guard on stop action and exit' do
      subject.should_receive(:extract_scopes_and_action).with('stop').and_return [{ }, :stop, []]
      ::Guard.should_receive(:stop)

      begin
        subject.process_input 'stop'
        raise 'Guard did not exit!'
      rescue SystemExit => e
        e.status.should eq(0)
      end
    end

    it 'pauses Guard on pause action' do
      subject.should_receive(:extract_scopes_and_action).with('pause').and_return [{ }, :pause, []]
      ::Guard.should_receive(:pause)
      subject.process_input 'pause'
    end

    it 'reloads Guard on reload action' do
      subject.should_receive(:extract_scopes_and_action).with('reload').and_return [{ }, :reload, []]
      ::Guard.should_receive(:reload).with({ })
      subject.process_input 'reload'
    end

    it 'runs an empty file change on change action' do
      subject.should_receive(:extract_scopes_and_action).with('change spec/guard_spec.rb').and_return [{ }, :change, ['spec/guard_spec.rb']]
      ::Guard.runner.should_receive(:run_on_changes).with(['spec/guard_spec.rb'], [], [])
      subject.process_input 'change spec/guard_spec.rb'
    end

    it 'runs all Guard on run_all action' do
      subject.should_receive(:extract_scopes_and_action).with('').and_return [{ }, :run_all, []]
      ::Guard.should_receive(:run_all).with({ })
      subject.process_input ''
    end

    it 'toggles the notifications on notification action' do
      subject.should_receive(:extract_scopes_and_action).with('notification').and_return [{ }, :notification, []]
      subject.should_receive(:toggle_notification)
      subject.process_input 'notification'
    end

    it 'shows an error on unknown action' do
      subject.should_receive(:extract_scopes_and_action).with('foo').and_return [{ }, :unknown, []]
      ::Guard::UI.should_receive(:error).with 'Unknown command foo'
      subject.process_input 'foo'
    end
  end

  describe 'toggle_notification' do
    before { ::Guard::UI.stub(:info) }

    it 'disables the notifications when enabled' do
      ENV['GUARD_NOTIFY'] = 'true'
      ::Guard::Notifier.should_receive(:turn_off)
      subject.toggle_notification
    end

    it 'enables the notifications when disabled' do
      ENV['GUARD_NOTIFY'] = 'false'
      ::Guard::Notifier.should_receive(:turn_on)
      subject.toggle_notification
    end
  end

  describe '#extract_scopes_and_action' do
    before(:all) do
      class Guard::Foo < Guard::Guard; end
      class Guard::FooBar < Guard::Guard; end
    end

    before(:each) do
      guard           = ::Guard.setup
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard1     = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_guard2     = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_bar_guard  = guard.add_guard('foo-bar', [], [], { :group => :frontend })
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:Foo)
        remove_const(:FooBar)
      end
    end

    context 'for blank command' do
      it 'returns :run_all action' do
        subject.extract_scopes_and_action('').should == [{ }, :run_all, []]
      end
    end

    context 'for an action command' do
      it 'returns the action if the command contains only a action' do
        subject.extract_scopes_and_action('exit').should == [{ }, :stop, []]
      end

      it 'returns the first action if the command contains multiple actions, removes all other actions' do
        subject.extract_scopes_and_action('change reload').should == [{ }, :change, []]
      end
    end

    context 'for a scope command' do
      it 'returns guard scope and run_all action if entry is only a guard scope' do
        subject.extract_scopes_and_action('foo-bar').should == [{ :guard => @foo_bar_guard }, :run_all, []]
      end

      it 'returns group scope and run_all action if entry is only a group scope' do
        subject.extract_scopes_and_action('backend').should == [{ :group => @backend_group }, :run_all, []]
      end

      it 'returns group scope and run_all action if entry is a group scope and not a action' do
        subject.extract_scopes_and_action('frontend x').should == [{ :group => @frontend_group }, :run_all, ['x']]
      end

      it 'returns the first group scope and drop the other scopes' do
        subject.extract_scopes_and_action('backend frontend').should == [{ :group => @backend_group }, :run_all, []]
        subject.extract_scopes_and_action('frontend backend').should == [{ :group => @frontend_group }, :run_all, []]
      end
    end

    context 'for an action and scope command' do
      it 'returns guard scope and action if entry is a guard scope and a action' do
        subject.extract_scopes_and_action('foo r').should == [{ :guard => @foo_guard1 }, :reload, []]
        subject.extract_scopes_and_action('r foo').should == [{ :guard => @foo_guard1 }, :reload, []]
      end

      it 'returns group scope and action if entry is a group scope and a action' do
        subject.extract_scopes_and_action('frontend r').should == [{ :group => @frontend_group }, :reload, []]
        subject.extract_scopes_and_action('r frontend').should == [{ :group => @frontend_group }, :reload, []]
      end
    end

    context 'for an invalid scope or command' do
      it 'returns no action if entry is not a scope or action' do
        subject.extract_scopes_and_action('x').should == [{ }, nil, ['x']]
      end

      it 'returns no action if entry is not a scope and not a action' do
        subject.extract_scopes_and_action('x x').should == [{ }, nil, ['x', 'x']]
      end
    end

    describe 'extracting actions' do
      it 'returns :help action for the help entry and for its shortcut' do
        %w{help h}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :help , []]
        end
      end

      it 'returns :reload action for the reload entry and for its shortcut' do
        %w{reload r}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :reload, []]
        end
      end

      it 'returns :stop action for exit or quit entry and for their shortcuts' do
        %w{exit e quit q}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :stop, []]
        end
      end

      it 'returns :pause action for the pause entry and for its shortcut' do
        %w{pause p}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :pause, []]
        end
      end

      it 'returns :notification action for the notification entry and for its shortcut' do
        %w{notification n}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :notification, []]
        end
      end

      it 'returns :show action for the show entry and for its shortcut' do
        %w{show s}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :show, []]
        end
      end

      it 'returns :change action for the show entry and for its shortcut' do
        %w{change c}.each do |e|
          subject.extract_scopes_and_action(e).should == [{ }, :change, []]
        end
      end
    end
  end

end
