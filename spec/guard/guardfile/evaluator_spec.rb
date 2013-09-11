require 'spec_helper'

describe Guard::Guardfile::Evaluator do

  let(:local_guardfile) { File.join(Dir.pwd, 'Guardfile') }
  let(:home_guardfile) { File.expand_path(File.join('~', '.Guardfile')) }
  let(:home_config) { File.expand_path(File.join('~', '.guard.rb')) }
  let(:guardfile_evaluator) { described_class.new }
  before do
    ::Guard.stub(:setup_interactor)
    ::Guard.setup
    ::Guard::Notifier.stub(:notify)
  end

  def self.disable_user_config
    before { File.stub(:exist?).with(home_config) { false } }
  end

  describe '.evaluate' do
    it 'displays an error message when Guardfile is not valid and raise original exception' do
      Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:/)

      expect { described_class.new(guardfile_contents: 'Bad Guardfile').evaluate_guardfile }.to raise_error(NoMethodError)
    end

    it 'displays an error message when no Guardfile is found' do
      guardfile_evaluator.stub(:_guardfile_default_path).and_return('no_guardfile_here')
      Guard::UI.should_receive(:error).with('No Guardfile found, please create one with `guard init`.')

      expect { guardfile_evaluator.evaluate_guardfile }.to raise_error
    end

    it 'doesn\'t display an error message when no Guard plugins are defined in Guardfile' do
      guardfile_evaluator = described_class.new(guardfile_contents: valid_guardfile_string)
      guardfile_evaluator.stub(:_instance_eval_guardfile)
      ::Guard.stub(:plugins).and_return([])
      Guard::UI.should_not_receive(:error)

      guardfile_evaluator.evaluate_guardfile
    end

    describe 'correctly throws errors when initializing with invalid data' do
      before { Guard::Guardfile::Evaluator.any_instance.stub(:_instance_eval_guardfile) }

      it 'raises error when there\'s a problem reading a file' do
        File.stub(:exist?).with('/def/Guardfile') { true }
        File.stub(:read).with('/def/Guardfile')   { raise Errno::EACCES.new('permission error') }

        Guard::UI.should_receive(:error).with(/^Error reading file/)
        expect { described_class.new(guardfile: '/def/Guardfile').evaluate_guardfile }.to raise_error
      end

      it 'raises error when given Guardfile doesn\'t exist' do
        File.stub(:exist?).with('/def/Guardfile') { false }

        Guard::UI.should_receive(:error).with(/No Guardfile exists at/)
        expect { described_class.new(guardfile: '/def/Guardfile').evaluate_guardfile }.to raise_error
      end

      it 'raises error when resorting to use default, finds no default' do
        File.stub(:exist?).with(local_guardfile) { false }
        File.stub(:exist?).with(home_guardfile) { false }

        Guard::UI.should_receive(:error).with('No Guardfile found, please create one with `guard init`.')
        expect { described_class.new.evaluate_guardfile }.to raise_error
      end

      it 'raises error when guardfile_content ends up empty or nil' do
        Guard::UI.should_receive(:error).with('No Guard plugins found in Guardfile, please add at least one.')
        described_class.new(guardfile_contents: '').evaluate_guardfile
      end

      it 'doesn\'t raise error when guardfile_content is nil (skipped)' do
        Guard::UI.should_not_receive(:error)
        expect { described_class.new(guardfile_contents: nil).evaluate_guardfile }.to_not raise_error
      end
    end

    describe 'it should select the correct data source for Guardfile' do
      before { Guard::Guardfile::Evaluator.any_instance.stub(:_instance_eval_guardfile) }
      disable_user_config

      it 'should use a string for initializing' do
        guardfile_evaluator = described_class.new(guardfile_contents: valid_guardfile_string)
        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
      end

      it 'should use a given file over the default loc' do
        guardfile_evaluator = described_class.new(guardfile: '/abc/Guardfile')
        fake_guardfile('/abc/Guardfile', 'guard :foo')

        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq 'guard :foo'
      end

      it 'should use a default file if no other options are given' do
        fake_guardfile(local_guardfile, 'guard :bar')

        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq 'guard :bar'
      end

      it 'should use a string over any other method' do
        guardfile_evaluator = described_class.new(guardfile_contents: valid_guardfile_string)
        fake_guardfile('/abc/Guardfile', 'guard :foo')
        fake_guardfile(local_guardfile, 'guard :bar')

        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
      end

      it 'should use the given Guardfile over default Guardfile' do
        guardfile_evaluator = described_class.new(guardfile: '/abc/Guardfile')
        fake_guardfile('/abc/Guardfile', 'guard :foo')
        fake_guardfile(local_guardfile, 'guard :bar')

        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq 'guard :foo'
      end

      it 'should append the user config file if present' do
        guardfile_evaluator = described_class.new(guardfile: '/abc/Guardfile')
        fake_guardfile('/abc/Guardfile', 'guard :foo')
        fake_guardfile(home_config, 'guard :bar')

        Guard::UI.should_not_receive(:error)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq "guard :foo\nguard :bar"
      end
    end

    describe 'correctly reads data from its valid data source' do
      before { ::Guard::Dsl.stub(:_instance_eval_guardfile) }
      disable_user_config

      it 'reads correctly from a string' do
        guardfile_evaluator = described_class.new(guardfile_contents: valid_guardfile_string)
        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
      end

      it 'reads correctly from a Guardfile' do
        guardfile_evaluator = described_class.new(guardfile: '/abc/Guardfile')
        fake_guardfile('/abc/Guardfile', 'guard :rspec')

        expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
        guardfile_evaluator.guardfile_contents.should eq 'guard :rspec'
      end

      context 'with a local Guardfile only' do
        it 'reads correctly from it' do
          fake_guardfile(local_guardfile, valid_guardfile_string)

          expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
          guardfile_evaluator.guardfile_path.should eq local_guardfile
          guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
        end
      end

      context 'with a home Guardfile only' do
        it 'reads correctly from it' do
          File.stub(:exist?).with(local_guardfile) { false }
          fake_guardfile(home_guardfile, valid_guardfile_string)

          expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
          guardfile_evaluator.guardfile_path.should eq home_guardfile
          guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
        end
      end

      context 'with both a local and a home Guardfile' do
        it 'reads correctly from the local Guardfile' do
          fake_guardfile(local_guardfile, valid_guardfile_string)
          fake_guardfile(home_guardfile, valid_guardfile_string)

          expect { guardfile_evaluator.evaluate_guardfile }.to_not raise_error
          guardfile_evaluator.guardfile_path.should eq local_guardfile
          guardfile_evaluator.guardfile_contents.should eq valid_guardfile_string
        end
      end
    end
  end

  describe '.reevaluate_guardfile' do
    before do
      guardfile_evaluator.stub(:_instance_eval_guardfile)
      ::Guard.runner.stub(:run)
    end
    let(:growl) { { name: :growl, options: {} } }

    it 'evaluates the Guardfile' do
      guardfile_evaluator.should_receive(:evaluate_guardfile)

      guardfile_evaluator.reevaluate_guardfile
    end

    it 'stops all Guards' do
      ::Guard.runner.should_receive(:run).with(:stop)

      guardfile_evaluator.reevaluate_guardfile
    end

    it 'reset all Guard plugins' do
      ::Guard.should_receive(:reset_plugins)

      guardfile_evaluator.reevaluate_guardfile
    end

    it 'resets all groups' do
      ::Guard.should_receive(:reset_groups)

      guardfile_evaluator.reevaluate_guardfile
    end

    it 'clears the notifications' do
       ::Guard::Notifier.turn_off
       ::Guard::Notifier.notifiers = [growl]
       ::Guard::Notifier.notifiers.should_not be_empty

       guardfile_evaluator.reevaluate_guardfile

       ::Guard::Notifier.notifiers.should be_empty
    end

    it 'removes the cached Guardfile content' do
      guardfile_evaluator.reevaluate_guardfile

      guardfile_evaluator.options.guardfile_content.should be_nil
    end

    context 'with notifications enabled' do
      before { ::Guard::Notifier.stub(:enabled?).and_return true }

      it 'enables the notifications again' do
        ::Guard::Notifier.should_receive(:turn_on)

        guardfile_evaluator.reevaluate_guardfile
      end
    end

    context 'with notifications disabled' do
      before { ::Guard::Notifier.stub(:enabled?).and_return false }

      it 'does not enable the notifications again' do
        ::Guard::Notifier.should_not_receive(:turn_on)

        guardfile_evaluator.reevaluate_guardfile
      end
    end

    context 'with Guards afterwards' do
      before do
        ::Guard.stub(:plugins).and_return([double('Guard::Dummy')])
        ::Guard.runner.stub(:run)
      end

      it 'shows a success message' do
        ::Guard::UI.should_receive(:info).with('Guardfile has been re-evaluated.')

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'shows a success notification' do
        ::Guard::Notifier.should_receive(:notify).with('Guardfile has been re-evaluated.', title: 'Guard re-evaluate')

        guardfile_evaluator.reevaluate_guardfile
      end

      it 'starts all Guards' do
        ::Guard.runner.should_receive(:run).with(:start)

        guardfile_evaluator.reevaluate_guardfile
      end
    end

    context 'without Guards afterwards' do
      before do
        ::Guard.stub(:plugins).and_return([])
      end

      it 'shows a failure notification' do
        ::Guard::Notifier.should_receive(:notify).with('No plugins found in Guardfile, please add at least one.', title: 'Guard re-evaluate', image: :failed)

        guardfile_evaluator.reevaluate_guardfile
      end
    end
  end

  describe '.guardfile_include?' do
    it 'detects a guard specified by a string with double quotes' do
      guardfile_evaluator.stub(_guardfile_contents_without_user_config: 'guard "test" {watch("c")}')

      guardfile_evaluator.guardfile_include?('test').should be_true
    end

    it 'detects a guard specified by a string with single quote' do
      guardfile_evaluator.stub(_guardfile_contents_without_user_config: 'guard \'test\' {watch("c")}')

      guardfile_evaluator.guardfile_include?('test').should be_true
    end

    it 'detects a guard specified by a symbol' do
      guardfile_evaluator.stub(_guardfile_contents_without_user_config: 'guard :test {watch("c")}')

      guardfile_evaluator.guardfile_include?('test').should be_true
    end

    it 'detects a guard wrapped in parentheses' do
      guardfile_evaluator.stub(_guardfile_contents_without_user_config: 'guard(:test) {watch("c")}')

      guardfile_evaluator.guardfile_include?('test').should be_true
    end
  end

  private

  def fake_guardfile(name, contents)
    File.stub(:exist?).with(name) { true }
    File.stub(:read).with(name)   { contents }
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
