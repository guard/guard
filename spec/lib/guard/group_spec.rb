require 'spec_helper'

describe Guard::Group do

  describe ".initialize" do
    it "accepts a name as a string and provides an accessor for it (returning a symbol)" do
      expect(described_class.new('foo').name).to eq :foo
    end

    it "accepts a name as a symbol and provides an accessor for it (returning a symbol)" do
      expect(described_class.new(:foo).name).to eq :foo
    end

    it "accepts options and provides an accessor for it" do
      expect(described_class.new('foo', halt_on_fail: true).options).to eq({ halt_on_fail: true })
    end
  end

  describe '#title' do
    it "output Group title properly" do
      group = described_class.new(:foo)
      expect(group.title).to eq 'Foo'
    end
  end

  describe '#to_s' do
    it "output Group properly" do
      group = described_class.new(:foo)
      expect(group.to_s).to eq '#<Guard::Group @name=foo @options={}>'
    end
  end

end
