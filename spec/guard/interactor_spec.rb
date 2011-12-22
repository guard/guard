require 'spec_helper'
require 'guard/guard'

describe Guard::Interactor do
  subject { Guard::Interactor.new }

  describe '#readline' do
    it 'must be implemented by a subclass' do
      expect { subject.read_line }.to raise_error(NotImplementedError)
    end
  end

  describe '.fabricate' do
    it 'returns the Readline interactor for a :readline symbol' do
      Guard::Interactor.interactor = :readline
      Guard::Interactor.fabricate.should be_an_instance_of(Guard::ReadlineInteractor)
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

  describe '#process_input' do
    it 'shows the help on help action' do
      subject.should_receive(:extract_scopes_and_action).with('help').and_return [{ }, :help]
      subject.should_receive(:help)
      subject.process_input 'help'
    end

    it 'stops Guard on stop action' do
      subject.should_receive(:extract_scopes_and_action).with('stop').and_return [{ }, :stop]
      ::Guard.should_receive(:stop)
      subject.process_input 'stop'
    end

    it 'pauses Guard on pause action' do
      subject.should_receive(:extract_scopes_and_action).with('pause').and_return [{ }, :pause]
      ::Guard.should_receive(:pause)
      subject.process_input 'pause'
    end

    it 'reloads Guard on reload action' do
      subject.should_receive(:extract_scopes_and_action).with('reload').and_return [{ }, :reload]
      subject.should_receive(:reload).with({ })
      subject.process_input 'reload'
    end

    it 'runs all Guard on run_all action' do
      subject.should_receive(:extract_scopes_and_action).with('').and_return [{ }, :run_all]
      ::Guard.should_receive(:run_all).with({ })
      subject.process_input ''
    end

    it 'toggles the notifications on notification action' do
      subject.should_receive(:extract_scopes_and_action).with('notification').and_return [{ }, :notification]
      subject.should_receive(:toggle_notification)
      subject.process_input 'notification'
    end

    it 'shows an error on unknown action' do
      subject.should_receive(:extract_scopes_and_action).with('foo').and_return [{ }, :unknown]
      ::Guard::UI.should_receive(:error).with 'Unknown command foo'
      subject.process_input 'foo'
    end
  end

  describe '#reload' do
    before do
      ::Guard.stub(:reload)
      ::Guard::Dsl.stub(:reevaluate_guardfile)
      ::Guard::UI.stub(:info)
    end

    context 'with a scope' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :group => :frontend })
      end

      it 'reloads Guard' do
        ::Guard.should_receive(:reload).with({ :group => :frontend })
        subject.reload({ :group => :frontend })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Dsl.should_receive(:reevaluate_guardfile)
        subject.reload({ })
      end

      it 'reloads Guard' do
        ::Guard.should_receive(:reload).with({ })
        subject.reload({ })
      end
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

    class Guard::Foo < Guard::Guard;
    end
    class Guard::FooBar < Guard::Guard;
    end

    before(:each) do
      guard           = ::Guard.setup
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @foo_bar_guard  = guard.add_guard('foo-bar', [], [], { :group => :frontend })
    end

    it 'returns :run_all action if entry is blank' do
      subject.extract_scopes_and_action('').should eql([{ }, :run_all])
    end

    it 'returns action if entry is only a action' do
      subject.extract_scopes_and_action('exit').should eql([{ }, :stop])
    end

    it 'returns guard scope and run_all action if entry is only a guard scope' do
      subject.extract_scopes_and_action('foo-bar').should eql([{ :guard => @foo_bar_guard }, :run_all])
    end

    it 'returns group scope and run_all action if entry is only a group scope' do
      subject.extract_scopes_and_action('backend').should eql([{ :group => @backend_group }, :run_all])
    end

    it 'returns no action if entry is not a scope or action' do
      subject.extract_scopes_and_action('x').should eql([{ }, nil])
    end

    it 'returns guard scope and action if entry is a guard scope and a action' do
      subject.extract_scopes_and_action('foo r').should eql([{ :guard => @foo_guard }, :reload])
    end

    it 'returns group scope and action if entry is a group scope and a action' do
      subject.extract_scopes_and_action('frontend r').should eql([{ :group => @frontend_group }, :reload])
    end

    it 'returns group scope and run_all action if entry is a group scope and not a action' do
      subject.extract_scopes_and_action('frontend x').should eql([{ :group => @frontend_group }, :run_all])
    end

    it 'returns no action if entry is not a scope and not a action' do
      subject.extract_scopes_and_action('x x').should eql([{ }, nil])
    end

    describe 'extracting actions' do
      it 'returns :help action for the help entry and for its shortcut' do
        %w{help h}.each do |e|
          subject.extract_scopes_and_action(e).should eql([{ }, :help])
        end
      end

      it 'returns :reload action for the reload entry and for its shortcut' do
        %w{reload r}.each do |e|
          subject.extract_scopes_and_action(e).should eql([{ }, :reload])
        end
      end

      it 'returns :stop action for exit or quit entry and for their shortcuts' do
        %w{exit e quit q}.each do |e|
          subject.extract_scopes_and_action(e).should eql([{ }, :stop])
        end
      end

      it 'returns :pause action for the pause entry and for its shortcut' do
        %w{pause p}.each do |e|
          subject.extract_scopes_and_action(e).should eql([{ }, :pause])
        end
      end

      it 'returns :notification action for the notification entry and for its shortcut' do
        %w{notification n}.each do |e|
          subject.extract_scopes_and_action(e).should eql([{ }, :notification])
        end
      end
    end
  end

end
