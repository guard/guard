# frozen_string_literal: true

require 'guard/cli/environments/valid'
require 'guard/cli/environments/bundler'

RSpec.describe Guard::Cli::Environments::Valid do
  subject { described_class.new(options) }
  let(:options) { double('options') }

  before do
    # TODO: start should be an instance method of something
    allow(Guard).to receive(:start)
  end

  describe '#start_guard' do
    let(:bundler) { instance_double('Guard::Cli::Environments::Bundler') }

    before do
      allow(Guard::Cli::Environments::Bundler).to receive(:new)
        .and_return(bundler)

      allow(bundler).to receive(:verify)
    end

    context 'with a valid bundler setup' do
      before do
        allow(bundler).to receive(:verify)

        allow(options).to receive(:[]).with(:no_bundler_warning)
          .and_return(false)
      end

      it 'starts guard' do
        expect(Guard).to receive(:start)
        subject.start_guard
      end

      it 'start guard with options' do
        expect(Guard).to receive(:start).with(options)
        subject.start_guard
      end

      it 'returns exit code' do
        exitcode = double('exitcode')
        expect(Guard).to receive(:start).and_return(exitcode)
        expect(subject.start_guard).to be(exitcode)
      end

      [
        Guard::Dsl::Error,
        Guard::Guardfile::Evaluator::NoPluginsError,
        Guard::Guardfile::Evaluator::NoGuardfileError,
        Guard::Guardfile::Evaluator::NoCustomGuardfile
      ].each do |error_class|
        context "when a #{error_class} error occurs" do
          before do
            allow(Guard).to receive(:start)
              .and_raise(error_class, "#{error_class} error!")
          end

          it 'aborts' do
            expect { subject.start_guard }.to raise_error(SystemExit)
          end

          it 'shows error message' do
            expect(Guard::UI).to receive(:error).with(/#{error_class} error!/)
            begin
              subject.start_guard
            rescue SystemExit
            end
          end
        end
      end
    end

    context 'without no_bundler_warning option' do
      subject { described_class.new(no_bundler_warning: false) }

      it 'verifies bundler presence' do
        expect(bundler).to receive(:verify)
        subject.start_guard
      end

      context 'without a valid bundler setup' do
        before do
          allow(bundler).to receive(:verify).and_raise(SystemExit)
        end

        it 'does not start guard' do
          expect(Guard).to_not receive(:start)

          begin
            subject.start_guard
          rescue SystemExit
          end
        end
      end
    end

    context 'with no_bundler_warning option' do
      subject { described_class.new(no_bundler_warning: true) }

      it 'does not verify bundler presence' do
        expect(bundler).to_not receive(:verify)
        subject.start_guard
      end

      it 'starts guard' do
        expect(Guard).to receive(:start)
        subject.start_guard
      end
    end

    describe 'return value' do
      let(:exitcode) { double('Fixnum') }
      subject { described_class.new(no_bundler_warning: true) }

      before do
        allow(Guard).to receive(:start).and_return(exitcode)
      end

      it 'matches return value of Guard.start' do
        expect(subject.start_guard).to be(exitcode)
      end
    end
  end

  describe '#initialize_guardfile' do
    let(:evaluator) { instance_double('Guard::Guardfile::Evaluator') }
    let(:generator) { instance_double('Guard::Guardfile::Generator') }
    let(:state) { instance_double('Guard::Internals::State') }
    let(:session) { instance_double('Guard::Internals::Session') }

    before do
      stub_file('Gemfile')

      allow(evaluator).to receive(:evaluate)
      allow(generator).to receive(:create_guardfile)
      allow(generator).to receive(:initialize_all_templates)

      allow(session).to receive(:evaluator_options)
      allow(state).to receive(:session).and_return(session)

      allow(Guard::Internals::State).to receive(:new).and_return(state)
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
      allow(Guard::Guardfile::Generator).to receive(:new).and_return(generator)
    end

    context 'with bare option' do
      before do
        expect(options).to receive(:[]).with(:bare).and_return(true)
      end

      it 'Only creates the Guardfile without initializing any Guard template' do
        allow(evaluator).to receive(:evaluate)
          .and_raise(Guard::Guardfile::Evaluator::NoGuardfileError)

        allow(File).to receive(:exist?).with('Gemfile').and_return(false)
        expect(generator).to receive(:create_guardfile)
        expect(generator).to_not receive(:initialize_template)
        expect(generator).to_not receive(:initialize_all_templates)

        subject.initialize_guardfile
      end

      it 'returns an exit code' do
        # TODO: ideally, we'd capture known exceptions and return nonzero
        expect(subject.initialize_guardfile).to be_zero
      end
    end

    context 'with no bare option' do
      before do
        expect(options).to receive(:[]).with(:bare).and_return(false)
      end

      it 'evaluates created or existing guardfile' do
        expect(evaluator).to receive(:evaluate)
        subject.initialize_guardfile
      end

      it 'creates a Guardfile' do
        expect(evaluator).to receive(:evaluate)
          .and_raise(Guard::Guardfile::Evaluator::NoGuardfileError).once
        expect(evaluator).to receive(:evaluate)

        expect(Guard::Guardfile::Generator).to receive(:new)
          .and_return(generator)
        expect(generator).to receive(:create_guardfile)

        subject.initialize_guardfile
      end

      it 'initializes templates of all installed Guards' do
        allow(File).to receive(:exist?).with('Gemfile').and_return(false)

        expect(generator).to receive(:initialize_all_templates)

        subject.initialize_guardfile
      end

      it 'initializes each passed template' do
        allow(File).to receive(:exist?).with('Gemfile').and_return(false)

        expect(generator).to receive(:initialize_template).with('rspec')
        expect(generator).to receive(:initialize_template).with('pow')

        subject.initialize_guardfile(%w[rspec pow])
      end

      context 'when passed a guard name' do
        context 'when the Guardfile is empty' do
          before do
            allow(evaluator).to receive(:evaluate)
              .and_raise Guard::Guardfile::Evaluator::NoPluginsError
            allow(generator).to receive(:initialize_template)
          end

          it 'works without without errors' do
            expect(subject.initialize_guardfile(%w[rspec])).to be_zero
          end

          it 'adds the template' do
            expect(generator).to receive(:initialize_template).with('rspec')
            subject.initialize_guardfile(%w[rspec])
          end
        end

        it 'initializes the template of the passed Guard' do
          expect(generator).to receive(:initialize_template).with('rspec')
          subject.initialize_guardfile(%w[rspec])
        end
      end

      it 'returns an exit code' do
        expect(subject.initialize_guardfile).to be_zero
      end

      context 'when passed an unknown guard name' do
        before do
          expect(generator).to receive(:initialize_template).with('foo')
            .and_raise(Guard::Guardfile::Generator::NoSuchPlugin, 'foo')
        end

        it 'returns an exit code' do
          expect(::Guard::UI).to receive(:error).with(
            "Could not load 'guard/foo' or '~/.guard/templates/foo'"\
            " or find class Guard::Foo\n"
          )
          expect(subject.initialize_guardfile(%w[foo])).to be(1)
        end
      end
    end
  end
end
