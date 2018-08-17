# frozen_string_literal: true

require 'guard/internals/state'

RSpec.describe Guard::Internals::State do
  let(:options) { {} }
  subject { described_class.new(options) }

  let(:scope) { instance_double('Guard::Internals::Scope') }
  let(:plugins) { instance_double('Guard::Internals::Plugins') }
  let(:groups) { instance_double('Guard::Internals::Groups') }
  let(:session) { instance_double('Guard::Internals::Session') }

  before do
    allow(Guard::Internals::Session).to receive(:new).and_return(session)
    allow(Guard::Internals::Scope).to receive(:new).and_return(scope)
    allow(session).to receive(:debug?).and_return(false)
    allow(session).to receive(:plugins).and_return(plugins)
    allow(session).to receive(:groups).and_return(groups)
  end

  describe '#initialize' do
    describe 'debugging' do
      let(:options) { { debug: debug } }
      before do
        allow(session).to receive(:debug?).and_return(debug)
        expect(Guard::Internals::Session).to receive(:new).with(debug: debug)
      end

      context 'when debug is set to true' do
        let(:debug) { true }
        it 'sets up debugging' do
          expect(Guard::Internals::Debugging).to receive(:start)
          subject
        end
      end

      context 'when debug is set to false' do
        let(:debug) { false }
        it 'does not set up debugging' do
          expect(Guard::Internals::Debugging).to_not receive(:start)
          subject
        end
      end
    end
  end
end
