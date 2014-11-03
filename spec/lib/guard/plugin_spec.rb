require "guard/plugin"

RSpec.describe Guard::Plugin do

  describe "#initialize" do
    it "assigns the defined watchers" do
      watchers = [Guard::Watcher.new("*")]
      expect(Guard::Plugin.new(watchers: watchers).watchers).to eq watchers
    end

    it "assigns the defined options" do
      options = { a: 1, b: 2 }
      expect(Guard::Plugin.new(options).options).to eq options
    end

    context "with a group in the options" do
      it "assigns the given group" do
        expect(Guard::Plugin.new(group: :test).group).to eq Guard.group(:test)
      end
    end

    context "without a group in the options" do
      it "assigns a default group" do
        expect(Guard::Plugin.new.group).to eq Guard.group(:default)
      end
    end
  end

end
