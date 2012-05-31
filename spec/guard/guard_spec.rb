require 'spec_helper'

describe Guard::Guard do

  describe '#initialize' do

    it 'assigns the defined watchers' do
      watchers = [ Guard::Watcher.new('*') ]
      guard = Guard::Guard.new(watchers)
      guard.watchers.should == watchers
    end

    it 'assigns the defined options' do
      options = { :a => 1, :b => 2 }
      guard = Guard::Guard.new([], options)
      guard.options.should == options
    end

    context 'with a group in the options' do
      it 'assigns the given group' do
        options = { :group => :test }
        guard = Guard::Guard.new([], options)
        guard.group.should == :test
      end
    end

    context 'without a group in the options' do
      it 'assigns a default group' do
        options = { }
        guard = Guard::Guard.new([], options)
        guard.group.should == :default
      end
    end
  end

  describe '#init' do
    context 'when the Guard is already in the Guardfile' do
      before { ::Guard::Dsl.stub(:guardfile_include?).and_return true }

      it 'shows an info message' do
        ::Guard::UI.should_receive(:info).with 'Guardfile already includes myguard guard'
        Guard::Guard.init('myguard')
      end
    end

    context 'when the Guard is not in the Guardfile' do
      before { ::Guard::Dsl.stub(:guardfile_include?).and_return false }

      it 'appends the template to the Guardfile' do
        File.should_receive(:read).with('Guardfile').and_return 'Guardfile content'
        ::Guard.should_receive(:locate_guard).with('myguard').and_return '/Users/me/projects/guard-myguard'
        File.should_receive(:read).with('/Users/me/projects/guard-myguard/lib/guard/myguard/templates/Guardfile').and_return('Template content')
        io = StringIO.new
        File.should_receive(:open).with('Guardfile', 'wb').and_yield io
        Guard::Guard.init('myguard')
        io.string.should == "Guardfile content\n\nTemplate content\n"
      end
    end
  end

  describe '#to_s' do
    before(:all) { class Guard::Dummy < Guard::Guard; end }

    it "output Guard properly" do
      guard = Guard::Dummy.new
      guard.to_s.should eq "Guard::Dummy"
    end
  end

end
