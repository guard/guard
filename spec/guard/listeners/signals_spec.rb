require 'spec_helper'
require 'guard/listener'

describe Guard::Listener do

  if windows? 
    STDERR.puts "ERROR guard listener signal testing not run because windows"
  else # ! windows

    describe 'when #initialize a new Listener' do
      let(:guard) { Guard::Listener.new }
      let(:ui) { Guard::UI }

      before { ENV['GUARD_ENV'] = 'test_signals' }
      after { ENV['GUARD_ENV'] = 'test' if ENV['GUARD_ENV'] == 'test_signals' }

      # ---- USR* signals while running

      context 'on an USR1 signal' do
        before { Process.kill :USR1, Process.pid }

        it '#pause once' do
          guard.should_receive(:pause).once
          guard.should_not_receive(:run).any_number_of_times

          ui.should_receive(:info).with("Paused Guard on signal USR1")
          ui.should_not_receive(:info).with("Continued Guard on signal USR2")
        end
      end

      context 'on an USR2 signal' do
        before { Process.kill :USR2, Process.pid }

        it 'does nothing' do
          guard.should_not_receive(:pause).any_number_of_times
          guard.should_not_receive(:run).any_number_of_times

          ui.should_not_receive(:info).with("Paused Guard on signal USR1")
          ui.should_not_receive(:info).with("Continued Guard on signal USR2")
        end
      end

      context 'on duplicate USR1 signals' do
        before do
          Process.kill :USR1, Process.pid
          Process.kill :USR1, Process.pid
        end

        it '#pause once' do
          guard.should_receive(:pause).once
          guard.should_receive(:run).any_number_of_times

          ui.should_receive(:info).with("Paused Guard on signal USR1")
          ui.should_not_receive(:info).with("Continued Guard on signal USR2")
        end
      end

      context 'on duplicate USR2 signals' do
        before do
          Process.kill :USR2, Process.pid
          Process.kill :USR2, Process.pid
        end

        it 'does nothing' do
          guard.should_not_receive(:pause).any_number_of_times
          guard.should_not_receive(:run).any_number_of_times

          ui.should_not_receive(:info).with("Paused Guard on signal USR1")
          ui.should_not_receive(:info).with("Continued Guard on signal USR2")
        end
      end

      context 'on an USR1 and then USR2 signal' do
        before do
          Process.kill :USR1, Process.pid
          Process.kill :USR2, Process.pid
        end

        it '#pause and then #run' do
          guard.should_receive(:pause).once
          guard.should_receive(:run).once

          ui.should_receive(:info).with("Paused Guard on signal USR1")
          ui.should_receive(:info).with("Continued Guard on signal USR2")
        end
      end

      context 'on an USR2 and then USR1 signal' do
        before do
          Process.kill :USR2, Process.pid
          Process.kill :USR1, Process.pid
        end

        it '#run once' do
          guard.should_receive(:pause).once
          guard.should_not_receive(:run).any_number_of_times

          ui.should_receive(:info).with("Paused Guard on signal USR1")
          ui.should_not_receive(:info).with("Continued Guard on signal USR2")
        end
      end

     
      # ---- USR* signals while started and then paused

      context 'when #pause' do
        before { guard.stub(:pause) }

        context 'on an USR1 signal' do
          before { Process.kill :USR1, Process.pid }

          it 'does nothing' do
            guard.should_not_receive(:pause).any_number_of_times
            guard.should_not_receive(:run).any_number_of_times

            ui.should_not_receive(:info).with("Paused Guard on signal USR1")
            ui.should_not_receive(:info).with("Continued Guard on signal USR2")
          end
        end

        context 'on an USR2 signal' do
          before { Process.kill :USR2, Process.pid }

          it '#pause once' do
            guard.should_not_receive(:pause).any_number_of_times
            guard.should_receive(:run).once

            ui.should_receive(:info).with("Paused Guard on signal USR1")
            ui.should_not_receive(:info).with("Paused Guard on signal USR1")
            ui.should_not_receive(:info).with("Continued Guard on signal USR2")
          end
        end

        context 'on duplicate USR1 signals' do
          before do
            Process.kill :USR1, Process.pid
            Process.kill :USR1, Process.pid
          end

          it 'does nothing' do
            guard.should_not_receive(:pause).any_number_of_times
            guard.should_not_receive(:run).any_number_of_times

            ui.should_not_receive(:info).with("Paused Guard on signal USR1")
            ui.should_not_receive(:info).with("Continued Guard on signal USR2")
          end
        end

        context 'on duplicate USR2 signals' do
          before do
            Process.kill :USR2, Process.pid
            Process.kill :USR2, Process.pid
          end

          it '#run once' do
            guard.should_not_receive(:pause).any_number_of_times
            guard.should_receive(:run).once

            ui.should_not_receive(:info).with("Paused Guard on signal USR1")
            ui.should_receive(:info).with("Continued Guard on signal USR2")
          end
        end

        context 'on an USR1 and then USR2 signal' do
          before do
            Process.kill :USR1, Process.pid
            Process.kill :USR2, Process.pid
          end

          it '#run once' do
            guard.should_not_receive(:pause).any_number_of_times
            guard.should_receive(:run).once

            ui.should_not_receive(:info).with("Paused Guard on signal USR1")
            ui.should_receive(:info).with("Continued Guard on signal USR2")
          end
        end

        context 'on an USR2 and then USR1 signal' do
          before do
            Process.kill :USR2, Process.pid
            Process.kill :USR1, Process.pid
          end

          it '#run and then #pause' do
            guard.should_not_receive(:pause).once
            guard.should_receive(:run).once

            ui.should_receive(:info).with("Paused Guard on signal USR1")
            ui.should_receive(:info).with("Continued Guard on signal USR2")
          end
        end
      end # when #pause

    end # describe when #start
  end # !windows
end # describe Guard::Listener
