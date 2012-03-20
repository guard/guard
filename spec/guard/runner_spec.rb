require 'spec_helper'

describe Guard::Runner do
  before do
    class Guard::Dummy < Guard::Guard
      def start
        throw :task_has_failed
      end
    end
    class Guard::Dumby < Guard::Guard
      def start
        throw :task_has_failed
      end
    end

    @guard = ::Guard.setup
    @frontend_group = @guard.add_group(:frontend)
    @backend_group  = @guard.add_group(:backend, { :halt_on_fail => true })

    @dummy_guard = @guard.add_guard(:dummy, [], [], { :group => :frontend })
    @guard.add_guard(:dummy, [], [], { :group => :frontend })

    @dumby_guard = @guard.add_guard(:dumby, [], [], { :group => :backend })
    @guard.add_guard(:dummy, [], [], { :group => :backend })

    @sum = { :foo => 0, :bar => 0 }
  end

  describe ".run_on_guards" do
    subject { ::Guard.setup }

    before do
      class Guard::Dummy < Guard::Guard; end
      class Guard::Dumby < Guard::Guard; end

      @foo_group = subject.add_group(:foo, { :halt_on_fail => true })
      subject.add_group(:bar)
      subject.add_guard(:dummy, [], [], { :group => :foo })
      subject.add_guard(:dummy, [], [], { :group => :foo })
      @dumby_guard = subject.add_guard(:dumby, [], [], { :group => :bar })
      subject.add_guard(:dummy, [], [], { :group => :bar })
      @sum = { :foo => 0, :bar => 0 }
    end

    context "all tasks succeed" do
      before do
        subject.guards.each { |guard| guard.stub!(:task) { @sum[guard.group] += 1; true } }
      end

      it "executes the task for each guard in each group" do
        subject.run_on_guards do |guard|
          guard.task
        end

        @sum.all? { |k, v| v == 2 }.should be_true
      end

      it "executes the task for each guard in foo group only" do
        subject.run_on_guards(:group => @foo_group) do |guard|
          guard.task
        end

        @sum[:foo].should eq 2
        @sum[:bar].should eq 0
      end

      it "executes the task for dumby guard only" do
        subject.run_on_guards(:guard => @dumby_guard) do |guard|
          guard.task
        end

        @sum[:foo].should eq 0
        @sum[:bar].should eq 1
      end
    end

    context "one guard fails" do
      before do
        subject.guards.each_with_index do |guard, i|
          guard.stub!(:task) do
            @sum[guard.group] += i+1
            if i % 2 == 0
              throw :task_has_failed
            else
              true
            end
          end
        end
      end

      it "executes the task only for guards that didn't fail for group with :halt_on_fail == true" do
        subject.run_on_guards do |guard|
          subject.run_supervised_task(guard, :task)
        end

        @sum[:foo].should eql 1
        @sum[:bar].should eql 7
      end
    end
  end

  describe ".run_on_change_task" do
    let(:guard) do
      guard = mock(Guard::Guard).as_null_object
      guard.stub!(:watchers) { [Guard::Watcher.new(/.+\.rb/)] }

      guard
    end

    it 'runs the :run_on_change task with the watched file changes' do
      Guard.should_receive(:run_supervised_task).with(guard, :run_on_change, ['a.rb', 'b.rb'])
      Guard.run_on_change_task(['a.rb', 'b.rb', 'templates/d.haml'], guard)
    end

    it 'runs the :run_on_deletion task with the watched file deletions' do
      Guard.should_receive(:run_supervised_task).with(guard, :run_on_deletion, ['c.rb'])
      Guard.run_on_change_task(['!c.rb', '!templates/e.haml'], guard)
    end
  end

  describe "#run_supervised_task(guard, task, *args)" do
    subject { described_class.new }

    %w[start stop reload run_all
      run_on_changes run_on_addtions run_on_modifications run_on_removals
      run_on_change run_on_deletion].each do |method_name|
      it "calls :#{method_name} on given guard" do
        @dummy_guard.should_receive(:send).with(method_name)

        subject.send :run_supervised_task, @dummy_guard, method_name
      end
    end

    context "task throw a :task_has_failed error and guard's group has :halt_on_fail to false" do
      it "catches the error" do
        expect { subject.send :run_supervised_task, @dummy_guard, :start }.to_not raise_error
      end
    end

    context "task throw a :task_has_failed error and guard's group has :halt_on_fail to true" do

      it "throws the error" do
        expect { subject.send :run_supervised_task, @dumby_guard, :start }.to throw_symbol(:task_has_failed)
      end

      it "calls UI.error" do
        Guard::UI.should_receive :error

        subject.send :run_supervised_task, @dumby_guard, :start
      end

      it "remove the failing guard from the current guards" do
        @guard.guards.should include(@dumby_guard)

        subject.send :run_supervised_task, @dumby_guard, :start

        @guard.guards.should_not include(@dumby_guard)
      end
    end
  end

end
