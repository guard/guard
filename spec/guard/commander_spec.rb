require 'spec_helper'
require 'guard/plugin'

describe Guard::Commander do
  describe '.start' do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(listener: double('listener', start: true))
      ::Guard.stub(runner: double('runner', run: true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    context 'Guard has not been setuped' do
      before { ::Guard.stub(:running) { false } }

      it "setup Guard" do
        ::Guard.should_receive(:setup).with(foo: 'bar')

        ::Guard.start(foo: 'bar')
      end
    end

    it "displays an info message" do
      ::Guard.instance_variable_set('@watchdirs', ['/foo/bar'])
      ::Guard::UI.should_receive(:info).with("Guard is now watching at '/foo/bar'")

      ::Guard.start
    end

    it "tell the runner to run the :start task" do
      ::Guard.runner.should_receive(:run).with(:start)

      ::Guard.start
    end

    it "start the listener" do
      ::Guard.listener.should_receive(:start)

      ::Guard.start
    end
  end

  describe '.stop' do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(listener: double('listener', stop: true))
      ::Guard.stub(runner: double('runner', run: true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    context 'Guard has not been setuped' do
      before { ::Guard.stub(:running) { false } }

      it "setup Guard" do
        ::Guard.should_receive(:setup)

        ::Guard.stop
      end
    end

    it "turns the notifier off" do
      ::Guard::Notifier.should_receive(:turn_off)

      ::Guard.stop
    end

    it "tell the runner to run the :stop task" do
      ::Guard.runner.should_receive(:run).with(:stop)

      ::Guard.stop
    end

    it "stops the listener" do
      ::Guard.listener.should_receive(:stop)

      ::Guard.stop
    end

    it "sets the running state to false" do
      ::Guard.running = true
      ::Guard.stop
      ::Guard.running.should be_false
    end
  end

  describe '.reload' do
    let(:runner) { double(run: true) }
    let(:group) { ::Guard::Group.new('frontend') }
    subject { ::Guard.setup }

    before do
      ::Guard.stub(:runner) { runner }
      ::Guard.stub(:within_preserved_state).and_yield
      ::Guard::UI.stub(:info)
      ::Guard::UI.stub(:clear)
    end

    context 'Guard has not been setuped' do
      before { ::Guard.stub(:running) { false } }

      it "setup Guard" do
        ::Guard.should_receive(:setup)

        ::Guard.reload
      end
    end

    it 'clears the screen' do
      ::Guard::UI.should_receive(:clear)

      subject.reload
    end

    context 'with a given scope' do
      it 'does not re-evaluate the Guardfile' do
        Guard::Guardfile::Evaluator.any_instance.should_not_receive(:reevaluate_guardfile)

        subject.reload({ groups: [group] })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { groups: [group] })

        subject.reload({ groups: [group] })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Guardfile::Evaluator.any_instance.should_receive(:reevaluate_guardfile)

        subject.reload
      end

      it 'does not reload Guard' do
        runner.should_not_receive(:run).with(:reload, {})

        subject.reload
      end
    end
  end

  describe '.run_all' do
    context 'Guard has not been setuped' do
      before { ::Guard.stub(:running) { false } }

      it "setup Guard" do
        ::Guard.should_receive(:setup)

        ::Guard.run_all
      end
    end
  end

  describe '.within_preserved_state' do
    subject { ::Guard.setup }
    before { subject.interactor = double('interactor').as_null_object }

    it 'disallows running the block concurrently to avoid inconsistent states' do
      subject.lock.should_receive(:synchronize)
      subject.within_preserved_state &Proc.new {}
    end

    it 'runs the passed block' do
      @called = false
      subject.within_preserved_state { @called = true }
      @called.should be_true
    end

    context '@running is true' do
      it 'stops the interactor before running the block and starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_receive(:start)
        subject.within_preserved_state &Proc.new {}
      end
    end

    context '@running is false' do
      before { ::Guard.stub(:running) { false } }

      it 'stops the interactor before running the block and do not starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_not_receive(:start)
        subject.within_preserved_state &Proc.new {}
      end
    end
  end

end
