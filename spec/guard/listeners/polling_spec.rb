require 'spec_helper'
require 'guard/listeners/polling'

describe Guard::Polling do
  subject { Guard::Polling }

  it_should_behave_like "a listener that reacts to #on_change"
  it_should_behave_like "a listener scoped to a specific directory"
end
