# frozen_string_literal: true
require 'guard/config'

unless Guard::Config.new.strict?

  require 'guard/deprecated/watcher'
  require 'guard/guardfile/evaluator'

  RSpec.describe Guard::Deprecated::Watcher do
    let(:session) { instance_double('Guard::Internals::Session') }

    subject do
      module TestModule; end.tap { |mod| described_class.add_deprecated(mod) }
    end

    let(:evaluator) { instance_double('Guard::Guardfile::Evaluator') }
    let(:options) { { guardfile: 'foo' } }

    let(:state) { instance_double('Guard::Internals::State') }

    before do
      allow(session).to receive(:evaluator_options).and_return(options)
      allow(state).to receive(:session).and_return(session)
      allow(Guard).to receive(:state).and_return(state)

      allow(evaluator).to receive(:guardfile_path)
        .and_return(File.expand_path('foo'))

      allow(::Guard::Guardfile::Evaluator).to receive(:new).with(options)
        .and_return(evaluator)

      allow(Guard::UI).to receive(:deprecation)
    end

    describe '.match_guardfile?' do
      it 'displays a deprecation warning to the user' do
        expect(Guard::UI).to receive(:deprecation)
          .with(Guard::Deprecated::Watcher::ClassMethods::MATCH_GUARDFILE)

        files = %w[foo bar]
        subject.match_guardfile?(files)
      end

      it 'matches against current guardfile' do
        expect(subject.match_guardfile?(%w[foo bar])).to be(true)
        expect(subject.match_guardfile?(%w[bar])).to be(false)
      end
    end
  end
end
