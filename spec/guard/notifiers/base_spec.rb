require 'spec_helper'

describe Guard::Notifier::Base do
  let(:gntp)  { mock('GNTP notifier', :name => 'gntp', :title => 'GNTP', :options => {}) }
  let(:growl) { mock('Growl notifier', :name => 'growl', :title => 'Growl', :options => {}) }

  class Guard::Notifier::FooBar < described_class
    def self.supported_hosts
      ['freebsd', 'solaris']
    end
  end

  before { subject.stub(:require) }

  describe '.name' do
    it 'un-modulizes the class, replaces "xY" with "x_Y" and downcase' do
      Guard::Notifier::FooBar.name.should eq 'foo_bar'
    end
  end

  describe '#name' do
    it 'delegates to the class' do
      Guard::Notifier::FooBar.new.name.should eq Guard::Notifier::FooBar.name
    end
  end

  describe '.title' do
    it 'un-modulize the class' do
      Guard::Notifier::FooBar.title.should eq 'FooBar'
    end
  end

  describe '#title' do
    it 'delegates to the class' do
      Guard::Notifier::FooBar.new.title.should eq Guard::Notifier::FooBar.title
    end
  end

  describe '.normalize_standard_options!' do
    context 'no opts given' do
      let(:opts) { {} }

      it 'returns the Guard title image when no :title is defined' do
        described_class.new.normalize_standard_options!(opts)

        opts[:title].should eq 'Guard'
      end

      it 'returns the :success type when no :type is defined' do
        described_class.new.normalize_standard_options!(opts)

        opts[:type].should eq :success
      end

      it 'returns the success.png image when no image is defined' do
        described_class.new.normalize_standard_options!(opts)

        opts[:image].should =~ /success.png/
      end
    end

    context ':title given' do
      let(:opts) { { :title => 'Hi' } }

      it 'returns the passed :title' do
        described_class.new.normalize_standard_options!(opts)

        opts[:title].should eq 'Hi'
      end
    end

    context ':type given' do
      let(:opts) { { :type => :foo } }

      it 'returns the passed :type' do
        described_class.new.normalize_standard_options!(opts)

        opts[:type].should eq :foo
      end
    end

    context ':image => :failed given' do
      let(:opts) { { :image => :failed } }

      it 'sets the "failed" type for a :failed image' do
        described_class.new.normalize_standard_options!(opts)

        opts[:image].should =~ /failed.png/
      end
    end

    context ':image => :pending given' do
      let(:opts) { { :image => :pending } }

      it 'sets the "pending" type for a :pending image' do
        described_class.new.normalize_standard_options!(opts)

        opts[:image].should =~ /pending.png/
      end
    end

    context ':image => :success given' do
      let(:opts) { { :image => :success } }

      it 'sets the "success" type for a :success image' do
        described_class.new.normalize_standard_options!(opts)

        opts[:image].should =~ /success.png/
      end
    end

    context ':image => "foo.png" given' do
      let(:opts) { { :image => 'foo.png' } }

      it 'sets the "success" type for a :success image' do
        described_class.new.normalize_standard_options!(opts)

        opts[:image].should eq 'foo.png'
      end
    end
  end

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :foo_bar notifier runs only on FreeBSD, Solaris.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'mswin'

        Guard::Notifier::FooBar.available?
      end
    end
  end

  describe '.require_gem_safely' do
    context 'library loads normally' do
      it 'returns true' do
        Guard::Notifier::FooBar.should_receive(:require).with('foo_bar')

        Guard::Notifier::FooBar.require_gem_safely.should be_true
      end
    end

    context 'library fails to load' do
      it 'shows an error message when the gem cannot be loaded' do
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'foo_bar'\" to your Gemfile and run Guard with \"bundle exec\"."
        Guard::Notifier::FooBar.should_receive(:require).with('foo_bar').and_raise LoadError

        Guard::Notifier::FooBar.require_gem_safely.should be_false
      end

      context 'with the silent option' do
        it 'does not show an error message when the gem cannot be loaded' do
          ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'growl_notify'\" to your Gemfile and run Guard with \"bundle exec\"."
          Guard::Notifier::FooBar.should_receive(:require).with('foo_bar').and_raise LoadError

          Guard::Notifier::FooBar.require_gem_safely(:silent => true).should be_false
        end
      end
    end

  end

end
