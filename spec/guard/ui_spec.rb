require 'spec_helper'

describe Guard::UI do
  after { Guard::UI.options = { :level => :info, :template => ':time - :severity - :message', :time_format => '%H:%M:%S' } }

  before do
    # The spec helper stubs all UI classes, so other specs doesn't have
    # to explicit take care of it. We unstub and move the stubs one layer
    # down just for this spec.
    Guard::UI.unstub(:info)
    Guard::UI.unstub(:warning)
    Guard::UI.unstub(:error)
    Guard::UI.unstub(:deprecation)
    Guard::UI.unstub(:debug)

    Guard::UI.logger.stub(:info)
    Guard::UI.logger.stub(:warn)
    Guard::UI.logger.stub(:error)
    Guard::UI.logger.stub(:deprecation)
    Guard::UI.logger.stub(:debug)
  end

  after do
    ::Guard::UI.stub(:info)
    ::Guard::UI.stub(:warning)
    ::Guard::UI.stub(:error)
    ::Guard::UI.stub(:debug)
    ::Guard::UI.stub(:deprecation)
  end

  describe '.logger' do
    it 'returns the logger instance' do
      Guard::UI.logger.should be_an_instance_of Lumberjack::Logger
    end
  end

  describe '.options=' do
    it 'sets the logger options' do
      Guard::UI.options = { :hi => :ho }
      Guard::UI.options.should eql({ :hi => :ho })
    end
  end

  describe '.info' do
    it 'resets the line with the :reset option' do
      Guard::UI.should_receive :reset_line
      Guard::UI.info('Info message', { :reset => true })
    end

    it 'logs the message to with the info severity' do
      Guard::UI.logger.should_receive(:info).with('Info message', 'Guard::UiSpec')
      Guard::UI.info 'Info message'
    end

    context 'with the :only option' do
      before { Guard::UI.options[:only] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_receive(:info).with('Info message', 'A')
        Guard::UI.logger.should_not_receive(:info).with('Info message', 'B')
        Guard::UI.logger.should_not_receive(:info).with('Info message', 'C')

        Guard::UI.info 'Info message', :plugin => 'A'
        Guard::UI.info 'Info message', :plugin => 'B'
        Guard::UI.info 'Info message', :plugin => 'C'
      end
    end

    context 'with the :except option' do
      before { Guard::UI.options[:except] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_not_receive(:info).with('Info message', 'A')
        Guard::UI.logger.should_receive(:info).with('Info message', 'B')
        Guard::UI.logger.should_receive(:info).with('Info message', 'C')

        Guard::UI.info 'Info message', :plugin => 'A'
        Guard::UI.info 'Info message', :plugin => 'B'
        Guard::UI.info 'Info message', :plugin => 'C'
      end
    end
  end

  describe '.warning' do
    it 'resets the line with the :reset option' do
      Guard::UI.should_receive :reset_line
      Guard::UI.warning('Warn message', { :reset => true })
    end

    it 'logs the message to with the warn severity' do
      Guard::UI.logger.should_receive(:warn).with("\e[0;33mWarn message\e[0m", 'Guard::UiSpec')
      Guard::UI.warning 'Warn message'
    end

    context 'with the :only option' do
      before { Guard::UI.options[:only] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mWarn message\e[0m", 'A')
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mWarn message\e[0m", 'B')
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mWarn message\e[0m", 'C')

        Guard::UI.warning 'Warn message', :plugin => 'A'
        Guard::UI.warning 'Warn message', :plugin => 'B'
        Guard::UI.warning 'Warn message', :plugin => 'C'
      end
    end

    context 'with the :except option' do
      before { Guard::UI.options[:except] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mWarn message\e[0m", 'A')
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mWarn message\e[0m", 'B')
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mWarn message\e[0m", 'C')

        Guard::UI.warning 'Warn message', :plugin => 'A'
        Guard::UI.warning 'Warn message', :plugin => 'B'
        Guard::UI.warning 'Warn message', :plugin => 'C'
      end
    end
  end

  describe '.error' do
    it 'resets the line with the :reset option' do
      Guard::UI.should_receive :reset_line
      Guard::UI.error('Error message', { :reset => true })
    end

    it 'logs the message to with the error severity' do
      Guard::UI.logger.should_receive(:error).with("\e[0;31mError message\e[0m", 'Guard::UiSpec')
      Guard::UI.error 'Error message'
    end

    context 'with the :only option' do
      before { Guard::UI.options[:only] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_receive(:error).with("\e[0;31mError message\e[0m", 'A')
        Guard::UI.logger.should_not_receive(:error).with("\e[0;31mError message\e[0m", 'B')
        Guard::UI.logger.should_not_receive(:error).with("\e[0;31mError message\e[0m", 'C')

        Guard::UI.error 'Error message', :plugin => 'A'
        Guard::UI.error 'Error message', :plugin => 'B'
        Guard::UI.error 'Error message', :plugin => 'C'
      end
    end

    context 'with the :except option' do
      before { Guard::UI.options[:except] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_not_receive(:error).with("\e[0;31mError message\e[0m", 'A')
        Guard::UI.logger.should_receive(:error).with("\e[0;31mError message\e[0m", 'B')
        Guard::UI.logger.should_receive(:error).with("\e[0;31mError message\e[0m", 'C')

        Guard::UI.error 'Error message', :plugin => 'A'
        Guard::UI.error 'Error message', :plugin => 'B'
        Guard::UI.error 'Error message', :plugin => 'C'
      end
    end
  end

  describe '.deprecation' do
    it 'resets the line with the :reset option' do
      Guard::UI.should_receive :reset_line
      Guard::UI.deprecation('Deprecation message', { :reset => true })
    end

    it 'logs the message to with the warn severity' do
      Guard::UI.logger.should_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'Guard::UiSpec')
      Guard::UI.deprecation 'Deprecation message'
    end

    context 'with the :only option' do
      before { Guard::UI.options[:only] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'A')
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'B')
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'C')

        Guard::UI.deprecation 'Deprecation message', :plugin => 'A'
        Guard::UI.deprecation 'Deprecation message', :plugin => 'B'
        Guard::UI.deprecation 'Deprecation message', :plugin => 'C'
      end
    end

    context 'with the :except option' do
      before { Guard::UI.options[:except] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_not_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'A')
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'B')
        Guard::UI.logger.should_receive(:warn).with("\e[0;33mDeprecation message\e[0m", 'C')

        Guard::UI.deprecation 'Deprecation message', :plugin => 'A'
        Guard::UI.deprecation 'Deprecation message', :plugin => 'B'
        Guard::UI.deprecation 'Deprecation message', :plugin => 'C'
      end
    end
  end

  describe '.debug' do
    it 'resets the line with the :reset option' do
      Guard::UI.should_receive :reset_line
      Guard::UI.debug('Debug message', { :reset => true })
    end

    it 'logs the message to with the debug severity' do
      Guard::UI.logger.should_receive(:debug).with("\e[0;33mDebug message\e[0m", 'Guard::UiSpec')
      Guard::UI.debug 'Debug message'
    end

    context 'with the :only option' do
      before { Guard::UI.options[:only] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_receive(:debug).with("\e[0;33mDebug message\e[0m", 'A')
        Guard::UI.logger.should_not_receive(:debug).with("\e[0;33mDebug message\e[0m", 'B')
        Guard::UI.logger.should_not_receive(:debug).with("\e[0;33mDebug message\e[0m", 'C')

        Guard::UI.debug 'Debug message', :plugin => 'A'
        Guard::UI.debug 'Debug message', :plugin => 'B'
        Guard::UI.debug 'Debug message', :plugin => 'C'
      end
    end

    context 'with the :except option' do
      before { Guard::UI.options[:except] = /A/ }

      it 'shows only the matching messages' do
        Guard::UI.logger.should_not_receive(:debug).with("\e[0;33mDebug message\e[0m", 'A')
        Guard::UI.logger.should_receive(:debug).with("\e[0;33mDebug message\e[0m", 'B')
        Guard::UI.logger.should_receive(:debug).with("\e[0;33mDebug message\e[0m", 'C')

        Guard::UI.debug 'Debug message', :plugin => 'A'
        Guard::UI.debug 'Debug message', :plugin => 'B'
        Guard::UI.debug 'Debug message', :plugin => 'C'
      end
    end
  end

  describe '.clear' do
    context 'when the Guard clear option is enabled' do
      before { ::Guard.stub(:options) { { :clear => true } } }

      it 'clears the outputs if clearable' do
        Guard::UI.clearable
        Guard::UI.should_receive(:system).with('clear;')
        Guard::UI.clear
      end

      it 'doesn not clear the output if already cleared' do
        Guard::UI.stub(:system)
        Guard::UI.clear
        Guard::UI.should_not_receive(:system).with('clear;')
        Guard::UI.clear
      end

      it 'clears the outputs if forced' do
        Guard::UI.stub(:system)
        Guard::UI.clear
        Guard::UI.should_receive(:system).with('clear;')
        Guard::UI.clear(:force => true)
      end
    end

    context 'when the Guard clear option is disabled' do
      before { ::Guard.stub(:options) { { :clear => false } } }

      it 'does not clear the output' do
        Guard::UI.should_not_receive(:system).with('clear;')
        Guard::UI.clear
      end
    end
  end

end
