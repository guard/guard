require 'spec_helper'
require 'guard/listeners/windows'

describe Guard::Windows do

  if linux?
    it "isn't usable on linux" do
      described_class.should_not be_usable
    end
  end

  if mac?
    it "isn't usable on Mac" do
      described_class.should_not be_usable
    end
  end

  if windows?
    it "is usable on Windows 2000 and later" do
      described_class.should be_usable
    end

    it_should_behave_like "a listener that reacts to #on_change"
    it_should_behave_like "a listener scoped to a specific directory"
  end

end
