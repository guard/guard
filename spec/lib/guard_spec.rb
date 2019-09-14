# frozen_string_literal: true

require "guard"

RSpec.describe Guard do
  describe '.init' do
    it 'creates a new Engine object' do
      cmdline_opts = { foo: :bar }

      expect(Guard::Engine).to receive(:new).with(cmdline_opts: cmdline_opts)

      described_class.init(cmdline_opts)
    end
  end
end
