require 'spec_helper'

describe Guard::Guardfile::Evaluator do

  let(:local_guardfile) { File.expand_path(File.join(Dir.pwd, 'Guardfile')) }
  let(:home_guardfile) { File.expand_path(File.join('~', '.Guardfile')) }
  let(:home_config) { File.expand_path(File.join('~', '.guard.rb')) }
  let(:guardfile_evaluator) { described_class.new }
  before do
    allow(::Guard).to receive(:setup_interactor)
    ::Guard.setup
    allow(::Guard::Notifier).to receive(:notify)
  end

  def self.disable_user_config
    before { allow(File).to receive(:exist?).with(home_config) { false } }
  end

  describe '.initialize' do
    disable_user_config

    context 'with the :guardfile_contents option' do
      let(:guardfile_evaluator) { described_class.new(guardfile_contents: valid_guardfile_string) }

      it 'uses the given Guardfile content' do
        guardfile_evaluator.evaluate_guardfile

        expect(guardfile_evaluator.guardfile_path).to eq 'Inline Guardfile'
        expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
      end
    end

    context 'with the :guardfile option' do
      let(:guardfile_evaluator) { described_class.new(guardfile: '../relative_path_to_Guardfile') }
      before { fake_guardfile(File.expand_path('../relative_path_to_Guardfile'), valid_guardfile_string) }

      it 'uses the given Guardfile content' do
        guardfile_evaluator.evaluate_guardfile

        expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('../relative_path_to_Guardfile')
        expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
      end
    end
  end

  describe '.evaluate_guardfile' do
    describe 'errors cases' do
      context 'with an invalid Guardfile' do
        it 'displays an error message and raises original exception' do
          expect(Guard::UI).to receive(:error).with(/Invalid Guardfile, original error is:/)
          expect { described_class.new(guardfile_contents: 'Bad Guardfile').evaluate_guardfile }.to raise_error(NoMethodError)
        end
      end

      context 'with no Guardfile at all' do
        it 'displays an error message and exits' do
          expect(File).to receive(:exist?).twice.and_return(false)
          expect(Guard::UI).to receive(:error).with('No Guardfile found, please create one with `guard init`.')
          expect { guardfile_evaluator.evaluate_guardfile }.to raise_error(SystemExit)
        end
      end

      context 'with a problem reading a Guardfile' do
        before { allow(File).to receive(:read).with(File.expand_path('Guardfile')) { raise Errno::EACCES.new('permission error') } }

        it 'displays an error message and exits' do
          expect(Guard::UI).to receive(:error).with(/^Error reading file/)
          expect { described_class.new.evaluate_guardfile }.to raise_error(SystemExit)
        end
      end

      context 'with empty Guardfile content' do
        let(:guardfile_evaluator) { described_class.new(guardfile_contents: '') }

        it 'does not display an error message' do
          expect(Guard::UI).to receive(:error).with('No Guard plugins found in Guardfile, please add at least one.')
          guardfile_evaluator.evaluate_guardfile
        end
      end

      context 'with Guardfile content is nil' do
        let(:guardfile_evaluator) { described_class.new(guardfile_contents: nil) }

        it 'does not raise error and skip it' do
          expect(Guard::UI).to_not receive(:error)
          expect { described_class.new(guardfile_contents: nil).evaluate_guardfile }.to_not raise_error
        end
      end

      context 'with a non-existing Guardfile given' do
        let(:guardfile_evaluator) { described_class.new(guardfile: '/non/existing/path/to/Guardfile') }

        it 'raises error' do
          expect(Guard::UI).to receive(:error).with('No Guardfile exists at /non/existing/path/to/Guardfile.')
          expect { guardfile_evaluator.evaluate_guardfile }.to raise_error
        end
      end
    end

    describe 'selection of the Guardfile data source' do
      before do
        allow_any_instance_of(Guard::Guardfile::Evaluator).to receive(:_instance_eval_guardfile)
      end
      disable_user_config

      context 'with no option' do
        let(:guardfile_evaluator) { described_class.new }

        context 'local Guardfile'  do
          before { fake_guardfile(local_guardfile, valid_guardfile_string) }

          it 'is the default' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('Guardfile')
          end

          it 'stores guardfile_path as expanded path' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('Guardfile')
          end

          it 'stores guardfile_contents as expected' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
          end

          context 'with a home Guardfile available' do
            before { fake_guardfile(home_guardfile, 'guard :bar') }

            it 'has precedence over home Guardfile' do
              guardfile_evaluator.evaluate_guardfile

              expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('Guardfile')
            end
          end

          context 'with a user config file available' do
            before { fake_guardfile(home_config, 'guard :bar') }

            it 'appends it to guardfile_contents' do
              guardfile_evaluator.evaluate_guardfile

              expect(guardfile_evaluator.guardfile_contents).to eq "#{valid_guardfile_string}\nguard :bar"
            end
          end
        end

        context 'home Guardfile'  do
          before do
            allow(File).to receive(:exist?).with(local_guardfile) { false }
            fake_guardfile(home_guardfile, valid_guardfile_string)
          end

          it 'stores guardfile_path as expanded path' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq home_guardfile
          end

          it 'stores guardfile_contents as expected' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
          end

          context 'with a user config file available' do
            before { fake_guardfile(home_config, 'guard :bar') }

            it 'appends it to guardfile_contents' do
              guardfile_evaluator.evaluate_guardfile

              expect(guardfile_evaluator.guardfile_contents).to eq "#{valid_guardfile_string}\nguard :bar"
            end
          end
        end
      end

      context 'with the :guardfile_contents option' do
        let(:guardfile_evaluator) { described_class.new(guardfile_contents: valid_guardfile_string) }

        it 'stores guardfile_path as "Inline Guardfile"' do
          guardfile_evaluator.evaluate_guardfile

          expect(guardfile_evaluator.guardfile_path).to eq 'Inline Guardfile'
        end

        it 'stores guardfile_contents as expected' do
          guardfile_evaluator.evaluate_guardfile

          expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
        end

        context 'with other Guardfiles available' do
          let(:guardfile_evaluator) { described_class.new(guardfile_contents: valid_guardfile_string, guardfile: '/abc/Guardfile') }
          before do
            fake_guardfile('/abc/Guardfile', 'guard :foo')
            fake_guardfile(local_guardfile, 'guard :bar')
            fake_guardfile(home_guardfile, 'guard :bar')
          end

          it 'has ultimate precedence' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq 'Inline Guardfile'
          end
        end

        context 'with a user config file available' do
          before { fake_guardfile(home_config, 'guard :bar') }

          it 'appends it to guardfile_contents' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_contents).to eq "#{valid_guardfile_string}\nguard :bar"
          end
        end
      end

      context 'with the :guardfile option' do
        let(:guardfile_evaluator) { described_class.new(guardfile: '../relative_path_to_Guardfile') }
        before do
          fake_guardfile(File.expand_path('../relative_path_to_Guardfile'), valid_guardfile_string)
          fake_guardfile('/abc/Guardfile', 'guard :foo')
        end

        context 'with a relative path to custom Guardfile' do
          it 'stores guardfile_path as expanded path' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('../relative_path_to_Guardfile')
          end
        end

        context 'with an absolute path to custom Guardfile' do
          let(:guardfile_evaluator) { described_class.new(guardfile: '/abc/Guardfile') }

          it 'stores guardfile_path as expanded path' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('/abc/Guardfile')
          end
        end

        it 'stores guardfile_contents as expected' do
          guardfile_evaluator.evaluate_guardfile

          expect(guardfile_evaluator.guardfile_contents).to eq valid_guardfile_string
        end

        context 'with other Guardfiles available' do
          before do
            fake_guardfile(local_guardfile, 'guard :bar')
            fake_guardfile(home_guardfile, 'guard :bar')
          end

          it 'has precedence over default Guardfiles' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_path).to eq File.expand_path('../relative_path_to_Guardfile')
          end
        end

        context 'with a user config file available' do
          before { fake_guardfile(home_config, 'guard :bar') }

          it 'appends it to guardfile_contents' do
            guardfile_evaluator.evaluate_guardfile

            expect(guardfile_evaluator.guardfile_contents).to eq "#{valid_guardfile_string}\nguard :bar"
          end
        end
      end
    end
  end

  describe '.reevaluate_guardfile' do
    before do
      allow(guardfile_evaluator).to receive(:_instance_eval_guardfile)
      allow(::Guard.runner).to receive(:run)
    end
    let(:growl) { { name: :growl, options: {} } }

    describe 'before reevaluation' do
      it 'stops all Guards' do
        expect(::Guard.runner).to receive(:run).with(:stop)

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'resets all Guard plugins' do
        expect(::Guard).to receive(:reset_plugins)

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'resets all groups' do
        expect(::Guard).to receive(:reset_groups)

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'resets all scopes' do
        expect(::Guard).to receive(:reset_scope)

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'clears the notifiers' do
         ::Guard::Notifier.turn_off
         ::Guard::Notifier.notifiers = [growl]
         expect(::Guard::Notifier.notifiers).to_not be_empty

         guardfile_evaluator.reevaluate_guardfile

         expect(::Guard::Notifier.notifiers).to be_empty
      end
    end

    it 'evaluates the Guardfile' do
      expect(guardfile_evaluator).to receive(:evaluate_guardfile)

      guardfile_evaluator.reevaluate_guardfile
    end

    describe 'after reevaluation' do
      context 'with notifications enabled' do
        before { allow(::Guard::Notifier).to receive(:enabled?).and_return(true) }

        it 'enables the notifications again' do
          expect(::Guard::Notifier).to receive(:turn_on)

          guardfile_evaluator.reevaluate_guardfile
        end
      end

      context 'with notifications disabled' do
        before { allow(::Guard::Notifier).to receive(:enabled?).and_return(false) }

        it 'does not enable the notifications again' do
          expect(::Guard::Notifier).to_not receive(:turn_on)

          guardfile_evaluator.reevaluate_guardfile
        end
      end

      context 'with Guards afterwards' do
        before do
          allow(::Guard).to receive(:plugins).and_return([double('Guard::Dummy')])
          allow(::Guard.runner).to receive(:run)
        end

        it 'shows a success message' do
          expect(::Guard::UI).to receive(:info).with('Guardfile has been re-evaluated.')

          guardfile_evaluator.reevaluate_guardfile
        end

        it 'shows a success notification' do
          expect(::Guard::Notifier).to receive(:notify).with('Guardfile has been re-evaluated.', title: 'Guard re-evaluate')

          guardfile_evaluator.reevaluate_guardfile
        end

        it 'starts all Guards' do
          expect(::Guard.runner).to receive(:run).with(:start)

          guardfile_evaluator.reevaluate_guardfile
        end
      end

      context 'without Guards afterwards' do
        it 'shows a failure notification' do
          expect(::Guard::Notifier).to receive(:notify).with('No plugins found in Guardfile, please add at least one.', title: 'Guard re-evaluate', image: :failed)

          guardfile_evaluator.options[:guardfile_contents] = ''
          guardfile_evaluator.reevaluate_guardfile
        end
      end

    end
  end

  describe '.guardfile_include?' do
    it 'detects a guard specified by a string with double quotes' do
      allow(guardfile_evaluator).to receive(:_guardfile_contents_without_user_config).and_return('guard "test" {watch("c")}')

      expect(guardfile_evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard specified by a string with single quote' do
      allow(guardfile_evaluator).to receive(:_guardfile_contents_without_user_config).and_return('guard \'test\' {watch("c")}')

      expect(guardfile_evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard specified by a symbol' do
      allow(guardfile_evaluator).to receive(:_guardfile_contents_without_user_config).and_return('guard :test {watch("c")}')

      expect(guardfile_evaluator.guardfile_include?('test')).to be_truthy
    end

    it 'detects a guard wrapped in parentheses' do
      allow(guardfile_evaluator).to receive(:_guardfile_contents_without_user_config).and_return('guard(:test) {watch("c")}')

      expect(guardfile_evaluator.guardfile_include?('test')).to be_truthy
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
