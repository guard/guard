require 'spec_helper'
require 'guard/plugin'

describe Guard::Deprecator do

  let!(:foo_guard) do
    stub_const 'Guard::Foo', Class.new(Guard::Plugin)
    ::Guard.setup.add_plugin(:foo, :group => :foo)
  end

  describe '.deprecated_options_warning' do
    context 'with watch_all_modifications options' do
      it 'displays a deprecation warning to the user' do
        ::Guard::UI.should_receive(:deprecation).with(described_class::WATCH_ALL_MODIFICATIONS_DEPRECATION)

        described_class.deprecated_options_warning(:watch_all_modifications => true)
      end
    end

    context 'with no_vendor options' do
      it 'displays a deprecation warning to the user' do
        ::Guard::UI.should_receive(:deprecation).with(described_class::NO_VENDOR_DEPRECATION)

        described_class.deprecated_options_warning(:no_vendor => true)
      end
    end

    describe '.deprecated_plugin_methods_warning' do
      before { ::Guard.stub(:plugins) { [foo_guard] } }

      context 'when neither run_on_change nor run_on_deletion is implemented in a guard' do
        it 'does not display a deprecation warning to the user' do
          ::Guard::UI.should_not_receive(:deprecation)

          described_class.deprecated_plugin_methods_warning
        end
      end

      context 'when run_on_change is implemented in a guard' do
        before { foo_guard.stub(:run_on_change) }

        it 'displays a deprecation warning to the user' do
          ::Guard::UI.should_receive(:deprecation).with(
            described_class::RUN_ON_CHANGE_DEPRECATION % foo_guard.class.name
          )

          described_class.deprecated_plugin_methods_warning
        end
      end

      context 'when run_on_deletion is implemented in a guard' do
        before { foo_guard.stub(:run_on_deletion) }

        it 'displays a deprecation warning to the user' do
          ::Guard::UI.should_receive(:deprecation).with(
            described_class::RUN_ON_DELETION_DEPRECATION % foo_guard.class.name
          )

          described_class.deprecated_plugin_methods_warning
        end
      end
    end

  end

end
