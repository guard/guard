require 'spec_helper'

describe Guard::Notifier do

  describe ".turn_off" do
    before do
      ENV["GUARD_NOTIFY"] = 'true'
      described_class.turn_off
    end

    it "disables the notifications" do
      ENV["GUARD_NOTIFY"].should eql 'false'
    end
  end

  describe ".turn_on" do
    context "on Mac OS" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'darwin'
      end

      context "with the GrowlNotify library available" do
        before do
          class ::GrowlNotify
            class GrowlNotFound < Exception; end
            def self.config ; end
          end
        end
        
        it "should respond properly to a GrowlNotify exception" do
          ::GrowlNotify.should_receive(:config).and_raise ::GrowlNotify::GrowlNotFound
          ::GrowlNotify.should_receive(:application_name).and_return ''
          ::Guard::UI.should_receive(:info)
          described_class.should_receive(:require).with('growl_notify').and_return true
          described_class.turn_on
          described_class.should_not be_enabled
        end

        it "loads the library and enables the notifications" do
          described_class.should_receive(:require).with('growl_notify').and_return true
          GrowlNotify.should_receive(:application_name).and_return ''
          described_class.turn_on
          described_class.should be_enabled
        end

        after do
          Object.send(:remove_const, :GrowlNotify)
        end
      end

      context "with the Growl library available" do
        it "loads the library and enables the notifications" do
          described_class.should_receive(:require).with('growl_notify').and_raise LoadError
          described_class.should_receive(:require).with('growl').and_return true
          described_class.turn_on
          described_class.should be_enabled
        end
      end

      context "without the Growl library available" do
        it "disables the notifications" do
          described_class.should_receive(:require).with('growl_notify').and_raise LoadError
          described_class.should_receive(:require).with('growl').and_raise LoadError
          described_class.turn_on
          described_class.should_not be_enabled
        end
      end
    end

    context "on Linux" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'linux'
      end

      context "with the Libnotify library available" do
        it "loads the library and enables the notifications" do
          described_class.should_receive(:require).with('libnotify').and_return true
          described_class.turn_on
          described_class.should be_enabled
        end
      end

      context "without the Libnotify library available" do
        it "disables the notifications" do
          described_class.should_receive(:require).with('libnotify').and_raise LoadError
          described_class.turn_on
          described_class.should_not be_enabled
        end
      end
    end

    context "on Windows" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'mswin'
      end

      context "with the rb-notifu library available" do
        it "loads the library and enables the notifications" do
          described_class.should_receive(:require).with('rb-notifu').and_return true
          described_class.turn_on
          described_class.should be_enabled
        end
      end

      context "without the rb-notify library available" do
        it "disables the notifications" do
          described_class.should_receive(:require).with('rb-notifu').and_raise LoadError
          described_class.turn_on
          described_class.should_not be_enabled
        end
      end
    end
  end

  describe ".notify" do
    before { described_class.stub(:enabled?).and_return(true) }

    context "on Mac OS" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'darwin'
        described_class.stub(:require_growl)
      end

      context 'with growl gem' do
        before do
          Object.send(:remove_const, :Growl) if defined?(Growl)
          Growl = Object.new
        end

        after do
          Object.send(:remove_const, :Growl)
        end

        it "passes the notification to Growl" do
          Growl.should_receive(:notify).with("great",
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :name  => "Guard"
          )
          described_class.notify 'great', :title => 'Guard'
        end

        it "don't passes the notification to Growl if library is not available" do
          Growl.should_not_receive(:notify)
          described_class.should_receive(:enabled?).and_return(true, false)
          described_class.notify 'great', :title => 'Guard'
        end

        it "allows additional notification options" do
          Growl.should_receive(:notify).with("great",
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :name  => "Guard",
            :priority => 1
          )
          described_class.notify 'great', :title => 'Guard', :priority => 1
        end

        it "allows to overwrite a default notification option" do
          Growl.should_receive(:notify).with("great",
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :name  => "Guard-Cucumber"
          )
          described_class.notify 'great', :title => 'Guard', :name => "Guard-Cucumber"
        end
      end

      context 'with growl_notify gem' do
        before do
          Object.send(:remove_const, :GrowlNotify) if defined?(GrowlNotify)
          GrowlNotify = Object.new
        end

        after do
          Object.send(:remove_const, :GrowlNotify)
        end

        it "passes the notification to Growl" do
          GrowlNotify.should_receive(:send_notification).with(
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :application_name  => "Guard",
            :description => 'great'
          )
          described_class.notify 'great', :title => 'Guard'
        end

        it "don't passes the notification to Growl if library is not available" do
          GrowlNotify.should_not_receive(:send_notification)
          described_class.should_receive(:enabled?).and_return(true, false)
          described_class.notify 'great', :title => 'Guard'
        end

        it "allows additional notification options" do
          GrowlNotify.should_receive(:send_notification).with(
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :application_name  => "Guard",
            :description => 'great',
            :priority => 1
          )
          described_class.notify 'great', :title => 'Guard', :priority => 1
        end

        it "throws out the application name since Guard should only use one Growl App Name while running" do
          GrowlNotify.should_receive(:send_notification).with(
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :application_name  => "Guard",
            :description => 'great'
          )
          described_class.notify 'great', :title => 'Guard', :name => "Guard-Cucumber"
        end
      end
    end

    context "on Linux" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'linux'
        described_class.stub(:require_libnotify)
        Object.send(:remove_const, :Libnotify) if defined?(Libnotify)
        Libnotify = Object.new
      end

      after do
        Object.send(:remove_const, :Libnotify)
      end

      it "passes the notification to Libnotify" do
        Libnotify.should_receive(:show).with(
          :body      => "great",
          :summary   => 'Guard',
          :icon_path => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
          :transient => true
        )
        described_class.notify 'great', :title => 'Guard'
      end

      it "don't passes the notification to Libnotify if library is not available" do
        Libnotify.should_not_receive(:show)
        described_class.should_receive(:enabled?).and_return(true, false)
        described_class.notify 'great', :title => 'Guard'
      end

      it "allows additional notification options" do
        Libnotify.should_receive(:show).with(
          :body      => "great",
          :summary   => 'Guard',
          :icon_path => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
          :transient => true,
          :urgency    => :critical
        )
        described_class.notify 'great', :title => 'Guard', :urgency => :critical
      end

      it "allows to overwrite a default notification option" do
        Libnotify.should_receive(:show).with(
          :body      => "great",
          :summary   => 'Guard',
          :icon_path => '~/.guard/success.png',
          :transient => true
        )
        described_class.notify 'great', :title => 'Guard', :icon_path => '~/.guard/success.png'
      end
    end

    context "on Windows" do
      before do
        RbConfig::CONFIG.should_receive(:[]).with('target_os').and_return 'mswin'
        described_class.stub(:require_rbnotifu)
        Object.send(:remove_const, :Notifu) if defined?(Notifu)
        Notifu = Object.new
      end

      after do
        Object.send(:remove_const, :Notifu)
      end

      it "passes the notification to rb-notifu" do
        Notifu.should_receive(:show).with(
          :message   => "great",
          :title     => 'Guard',
          :type      => :info,
          :time      => 3
        )
        described_class.notify 'great', :title => 'Guard'
      end

      it "don't passes the notification to rb-notifu if library is not available" do
        Notifu.should_not_receive(:show)
        described_class.should_receive(:enabled?).and_return(true, false)
        described_class.notify 'great', :title => 'Guard'
      end

      it "allows additional notification options" do
        Notifu.should_receive(:show).with(
          :message   => "great",
          :title     => 'Guard',
          :type      => :info,
          :time      => 3,
          :nosound   => true
        )
        described_class.notify 'great', :title => 'Guard', :nosound => true
      end

      it "allows to overwrite a default notification option" do
        Notifu.should_receive(:show).with(
          :message   => "great",
          :title     => 'Guard',
          :type      => :info,
          :time      => 10
        )
        described_class.notify 'great', :title => 'Guard', :time => 10
      end
    end
  end

  describe ".enabled?" do
    context "when enabled" do
      before { ENV["GUARD_NOTIFY"] = 'true' }

      it { should be_enabled }
    end

    context "when disabled" do
      before { ENV["GUARD_NOTIFY"] = 'false' }

      it { should_not be_enabled }
    end
  end

end
