require 'spec_helper'

describe Guard::Interactor do

  describe '.convert_scope' do
    before do
      guard           = ::Guard.setup

      stub_const 'Guard::Foo', Class.new(Guard::Guard)
      stub_const 'Guard::Bar', Class.new(Guard::Guard)

      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @bar_guard      = guard.add_guard(:bar, [], [], { :group => :frontend })
    end

    it 'returns a group scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(backend)
      scopes.should eql({ :group => @backend_group })
      scopes, _ = Guard::Interactor.convert_scope %w(frontend)
      scopes.should eql({ :group => @frontend_group })
    end

    it 'returns a plugin scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo)
      scopes.should eql({ :guard => @foo_guard })
      scopes, _ = Guard::Interactor.convert_scope %w(bar)
      scopes.should eql({ :guard => @bar_guard })
    end

    it 'returns the unkown scopes' do
      _, unkown = Guard::Interactor.convert_scope %w(unkown scope)
      unkown.should eql %w(unkown scope)
    end

  end
end
