require 'spec_helper'

describe Guard::Guardfile::Evaluator do

  let(:local_guardfile) { File.expand_path(File.join(Dir.pwd, 'Guardfile')) }
  let(:home_guardfile) { File.expand_path(File.join('~', '.Guardfile')) }
  let(:home_config) { File.expand_path(File.join('~', '.guard.rb')) }
  let(:evaluator) { described_class.new }

  let(:rel_guardfile) { File.expand_path('../relative_path_to_Guardfile') }

  before do
    allow(::Guard).to receive(:setup_interactor)
    allow(Guard::Notifier).to receive(:turn_on)
    ::Guard.setup
    allow(Guard::Notifier).to receive(:notify)
  end

  def self.disable_user_config
    before { allow(File).to receive(:exist?).with(home_config) { false } }
  end

  describe '.initialize' do
    disable_user_config

    context 'with the :guardfile_contents option' do
      let(:evaluator) do
        described_class.new(guardfile_contents: valid_guardfile_string)
      end

      it 'uses the given Guardfile content' do
        evaluator.evaluate_guardfile

        expect(evaluator.guardfile_path).to be_nil
        expect(evaluator.guardfile_source).to eq :inline
        expect(evaluator.guardfile_contents).to eq valid_guardfile_string
      end
    end

    context 'with the :guardfile option' do
      let(:evaluator) do
        described_class.new(guardfile: rel_guardfile)
      end

      before do
        fake_guardfile(rel_guardfile, valid_guardfile_string)
      end

      it 'uses the given Guardfile content' do
        evaluator.evaluate_guardfile
        expect(evaluator.guardfile_path).to eq rel_guardfile
        expect(evaluator.guardfile_source).to eq :custom
        expect(evaluator.guardfile_contents).to eq valid_guardfile_string
      end
    end
  end

  describe '.evaluate_guardfile' do
    describe 'errors cases' do
      context 'with an invalid Guardfile' do
        it 'displays an error message and raises original exception' do
          expect(Guard::UI).to receive(:error).
            with(/Invalid Guardfile, original error is:/)

          expect do
            guardfile = described_class.new(guardfile_contents: 'Bad Guardfile')
            guardfile.evaluate_guardfile
          end.to raise_error(NoMethodError)
        end
      end

      context 'with no Guardfile at all' do
        it 'displays an error message and exits' do
          expect(File).to receive(:exist?).twice.and_return(false)

          expect(Guard::UI).to receive(:error).
            with('No Guardfile found, please create one with `guard init`.')

          expect { evaluator.evaluate_guardfile }.to raise_error(SystemExit)
        end
      end

      context 'with a problem reading a Guardfile' do
        before do
          allow(File).to receive(:read).with(File.expand_path('Guardfile')) do
            fail Errno::EACCES.new('permission error')
          end
        end

        it 'displays an error message and exits' do
          expect(Guard::UI).to receive(:error).with(/^Error reading file/)
          expect { subject.evaluate_guardfile }.to raise_error(SystemExit)
        end
      end

      context 'with empty Guardfile content' do
        let(:evaluator) { described_class.new(guardfile_contents: '') }

        it 'does not display an error message' do
          expect(Guard::UI).to receive(:error).
            with('No Guard plugins found in Guardfile,'\
                 ' please add at least one.')

          evaluator.evaluate_guardfile
        end
      end

      context 'with Guardfile content is nil' do
        let(:evaluator) { described_class.new(guardfile_contents: nil) }

        it 'does not raise error and skip it' do
          expect(Guard::UI).to_not receive(:error)
          expect do
            described_class.new(guardfile_contents: nil).evaluate_guardfile
          end.to_not raise_error
        end
      end

      context 'with a non-existing Guardfile given' do
        let(:evaluator) do
          described_class.new(guardfile: '/non/existing/path/to/Guardfile')
        end

        it 'raises error' do
          expect(Guard::UI).to receive(:error).
            with('No Guardfile exists at /non/existing/path/to/Guardfile.')

          expect { evaluator.evaluate_guardfile }.to raise_error
        end
      end
    end

    describe 'selection of the Guardfile data source' do
      before do
        allow_any_instance_of(Guard::Guardfile::Evaluator).
          to receive(:_instance_eval_guardfile)

      end
      disable_user_config

      context 'with no option' do
        let(:evaluator) { described_class.new }
        let(:path) { File.expand_path('Guardfile') }

        context 'local Guardfile'  do
          before { fake_guardfile(local_guardfile, valid_guardfile_string) }

          it 'is the default' do
            evaluator.evaluate_guardfile
            expect(evaluator.guardfile_path).to eq path
          end

          it 'stores guardfile_source as :default' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_source).to eq :default
          end

          it 'stores guardfile_path as expanded path' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_path).to eq path
          end

          it 'stores guardfile_contents as expected' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_contents).to eq valid_guardfile_string
          end

          context 'with a home Guardfile available' do
            before { fake_guardfile(home_guardfile, 'guard :bar') }

            it 'has precedence over home Guardfile' do
              evaluator.evaluate_guardfile

              path = File.expand_path('Guardfile')
              expect(evaluator.guardfile_path).to eq path
            end
          end

          context 'with a user config file available' do
            before { fake_guardfile(home_config, 'guard :bar') }

            it 'appends it to guardfile_contents' do
              evaluator.evaluate_guardfile

              contents = "#{valid_guardfile_string}\nguard :bar"
              expect(evaluator.guardfile_contents).to eq contents
            end
          end
        end

        context 'home Guardfile'  do
          before do
            allow(File).to receive(:exist?).with(local_guardfile) { false }
            fake_guardfile(home_guardfile, valid_guardfile_string)
          end

          it 'stores guardfile_source as :default' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_source).to eq :default
          end

          it 'stores guardfile_path as expanded path' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_path).to eq home_guardfile
          end

          it 'stores guardfile_contents as expected' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_contents).to eq valid_guardfile_string
          end

          context 'with a user config file available' do
            before { fake_guardfile(home_config, 'guard :bar') }

            it 'appends it to guardfile_contents' do
              evaluator.evaluate_guardfile

              expected = "#{valid_guardfile_string}\nguard :bar"
              expect(evaluator.guardfile_contents).to eq expected
            end
          end
        end
      end

      context 'with the :guardfile_contents option' do
        let(:evaluator) do
          described_class.new(guardfile_contents: valid_guardfile_string)
        end

        it 'stores guardfile_source as :default' do
          evaluator.evaluate_guardfile

          expect(evaluator.guardfile_source).to eq :inline
        end

        it 'stores guardfile_path as nil' do
          evaluator.evaluate_guardfile

          expect(evaluator.guardfile_path).to be_nil
        end

        it 'stores guardfile_contents as expected' do
          evaluator.evaluate_guardfile

          expect(evaluator.guardfile_contents).to eq valid_guardfile_string
        end

        context 'with other Guardfiles available' do
          let(:evaluator) do
            described_class.new(guardfile_contents: valid_guardfile_string,
                                guardfile: '/abc/Guardfile')
          end

          before do
            fake_guardfile('/abc/Guardfile', 'guard :foo')
            fake_guardfile(local_guardfile, 'guard :bar')
            fake_guardfile(home_guardfile, 'guard :bar')
          end

          it 'has ultimate precedence' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_path).to be_nil
          end
        end

        context 'with a user config file available' do
          before { fake_guardfile(home_config, 'guard :bar') }

          it 'appends it to guardfile_contents' do
            evaluator.evaluate_guardfile

            expected = "#{valid_guardfile_string}\nguard :bar"
            expect(evaluator.guardfile_contents).to eq expected
          end
        end
      end

      context 'with the :guardfile option' do

        let(:evaluator) do
          described_class.new(guardfile: '../relative_path_to_Guardfile')
        end

        before do
          fake_guardfile(rel_guardfile, valid_guardfile_string)
          fake_guardfile('/abc/Guardfile', 'guard :foo')
        end

        it 'stores guardfile_source as :custom' do
          evaluator.evaluate_guardfile
          expect(evaluator.guardfile_source).to eq :custom
        end

        context 'with a relative path to custom Guardfile' do
          it 'stores guardfile_path as expanded path' do
            evaluator.evaluate_guardfile
            expect(evaluator.guardfile_path).to eq rel_guardfile
          end
        end

        context 'with an absolute path to custom Guardfile' do
          let(:evaluator) { described_class.new(guardfile: '/abc/Guardfile') }

          it 'stores guardfile_path as expanded path' do
            evaluator.evaluate_guardfile

            expected = File.expand_path('/abc/Guardfile')
            expect(evaluator.guardfile_path).to eq expected
          end
        end

        it 'stores guardfile_contents as expected' do
          evaluator.evaluate_guardfile

          expect(evaluator.guardfile_contents).to eq valid_guardfile_string
        end

        context 'with other Guardfiles available' do
          before do
            fake_guardfile(local_guardfile, 'guard :bar')
            fake_guardfile(home_guardfile, 'guard :bar')
          end

          it 'has precedence over default Guardfiles' do
            evaluator.evaluate_guardfile

            expect(evaluator.guardfile_path).to eq rel_guardfile
          end
        end

        context 'with a user config file available' do
          before { fake_guardfile(home_config, 'guard :bar') }

          it 'appends it to guardfile_contents' do
            evaluator.evaluate_guardfile

            expected = "#{valid_guardfile_string}\nguard :bar"
            expect(evaluator.guardfile_contents).to eq expected
          end
        end
      end
    end
  end

  describe '.reevaluate_guardfile' do
    before do
      allow(::Guard.runner).to receive(:run)
      evaluator.evaluate_guardfile
    end
    let(:growl) { { name: :growl, options: {} } }

    context 'with the :guardfile_contents option' do
      let(:evaluator) do
        described_class.new(guardfile_contents: valid_guardfile_string)
      end

      it 'skips the reevaluation' do
        expect(evaluator).to_not receive(:_before_reevaluate_guardfile)
        expect(evaluator).to_not receive(:evaluate_guardfile)
        expect(evaluator).to_not receive(:_after_reevaluate_guardfile)

        evaluator.reevaluate_guardfile
      end
    end

    describe 'before reevaluation' do
      it 'stops all Guards' do
        expect(::Guard.runner).to receive(:run).with(:stop)

        evaluator.reevaluate_guardfile
      end

      it 'resets all Guard plugins' do
        expect(::Guard).to receive(:reset_plugins)

        evaluator.reevaluate_guardfile
      end

      it 'resets all groups' do
        expect(::Guard).to receive(:reset_groups)

        evaluator.reevaluate_guardfile
      end

      it 'resets all scopes' do
        expect(::Guard).to receive(:reset_scope)

        evaluator.reevaluate_guardfile
      end

      it 'clears the notifiers' do
        ::Guard::Notifier.turn_off
        ::Guard::Notifier.notifiers = [growl]
        expect(::Guard::Notifier.notifiers).to_not be_empty

        evaluator.reevaluate_guardfile

        expect(::Guard::Notifier.notifiers).to be_empty
      end
    end

    it 'evaluates the Guardfile' do
      expect(evaluator).to receive(:evaluate_guardfile)

      evaluator.reevaluate_guardfile
    end

    describe 'after reevaluation' do
      context 'with notifications enabled' do
        before { allow(::Guard::Notifier).to receive(:enabled?) { true } }

        it 'enables the notifications again' do
          expect(::Guard::Notifier).to receive(:turn_on)

          evaluator.reevaluate_guardfile
        end
      end

      context 'with notifications disabled' do
        before { allow(::Guard::Notifier).to receive(:enabled?) { false } }

        it 'does not enable the notifications again' do
          expect(::Guard::Notifier).to_not receive(:turn_on)

          evaluator.reevaluate_guardfile
        end
      end

      context 'with Guards afterwards' do
        before do
          expect(evaluator).to receive(:guardfile_contents).
            exactly(3) { 'guard :rspec' }

          allow(::Guard.runner).to receive(:run)
        end

        it 'shows a success message' do
          expect(::Guard::UI).to receive(:info).
            with('Guardfile has been re-evaluated.')

          evaluator.reevaluate_guardfile
        end

        it 'shows a success notification' do
          expect(::Guard::Notifier).to receive(:notify).
            with('Guardfile has been re-evaluated.', title: 'Guard re-evaluate')

          evaluator.reevaluate_guardfile
        end

        it 'starts all Guards' do
          expect(::Guard.runner).to receive(:run).with(:start)

          evaluator.reevaluate_guardfile
        end
      end

      context 'without Guards afterwards' do
        it 'shows a failure notification' do
          expect(::Guard::Notifier).to receive(:notify).
            with(
              'No plugins found in Guardfile, please add at least one.',
              title: 'Guard re-evaluate',
              image: :failed)

          expect(evaluator).to receive(:guardfile_contents).exactly(3) { '' }
          evaluator.reevaluate_guardfile
        end
      end
    end
  end

  describe '.guardfile_include?' do
    it 'detects a guard specified by a string with double quotes' do
      allow(evaluator).to receive(:_guardfile_contents_without_user_config).
        and_return('guard "test" {watch("c")}')

      expect(evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard specified by a string with single quote' do
      allow(evaluator).to receive(:_guardfile_contents_without_user_config).
        and_return('guard \'test\' {watch("c")}')

      expect(evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard specified by a symbol' do
      allow(evaluator).to receive(:_guardfile_contents_without_user_config).
        and_return('guard :test {watch("c")}')

      expect(evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard wrapped in parentheses' do
      allow(evaluator).to receive(:_guardfile_contents_without_user_config).
        and_return('guard(:test) {watch("c")}')

      expect(evaluator.guardfile_include?('test')).to be_truthy
    end
  end

  private

  def fake_guardfile(name, contents)
    allow(File).to receive(:exist?).with(name) { true }
    allow(File).to receive(:read).with(name)   { contents }
  end

  def valid_guardfile_string
    '
    notification :growl

    guard :rspec

    group :w do
      guard :rspec
    end

    group :x, halt_on_fail: true do
      guard :rspec
      guard :rspec
    end

    group :y do
      guard :rspec
    end
    '
  end
end
