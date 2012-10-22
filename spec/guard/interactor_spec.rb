require 'spec_helper'

describe Guard::Interactor do

  describe '.convert_scope' do
    before(:all) do
      class Guard::Foo < Guard::Guard; end
      class Guard::Bar < Guard::Guard; end
    end

    before(:each) do
      guard           = ::Guard.setup
      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_guard(:foo, [], [], { :group => :backend })
      @bar_guard      = guard.add_guard(:bar, [], [], { :group => :frontend })
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:Foo)
        remove_const(:Bar)
      end
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
