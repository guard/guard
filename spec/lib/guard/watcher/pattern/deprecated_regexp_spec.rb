# frozen_string_literal: true

require "guard/watcher/pattern/deprecated_regexp"

RSpec.describe Guard::Watcher::Pattern::DeprecatedRegexp do
  describe ".deprecated?" do
    specify { expect(described_class.new("^spec_helper.rb")).to be_deprecated }
    specify { expect(described_class.new("spec_helper.rb$")).to be_deprecated }
  end

  describe "Matcher returned by .convert" do
    let(:matcher) { Guard::Watcher::Pattern::Matcher }

    before { allow(matcher).to receive(:new) }

    {
      "^foo.rb" => /^foo.rb/,
      "foo.rb$" => /foo.rb$/,
      'foo\.rb' => /foo\.rb/,
      ".*rb" => /.*rb/
    }.each do |pattern, regexp|
      context "with #{pattern}" do
        it "creates a Matcher with #{regexp}" do
          expect(matcher).to receive(:new).with(regexp)
          described_class.convert(pattern)
        end
      end
    end
  end
end
