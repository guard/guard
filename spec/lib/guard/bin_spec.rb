# frozen_string_literal: true

path = File.expand_path('../../../../bin/guard', __FILE__)
load path

RSpec.describe GuardReloader do
  let(:config) { instance_double(described_class::Config) }

  subject { described_class.new(config) }

  let(:guard_core_path) { '/home/me/.rvm/gems/ruby-2.2.2/bin/_guard-core' }

  before do
    allow(described_class::Config).to receive(:new).and_return(config)

    allow(config).to receive(:current_bundler_gemfile)
      .and_return(bundle_gemfile_env)

    allow(config).to receive(:using_bundler?).and_return(bundle_gemfile_env)
    allow(config).to receive(:guard_core_path).and_return(guard_core_path)

    allow(config).to receive(:program_arguments).and_return(%w[foo bar baz])
    allow(config).to receive(:using_rubygems?).and_return(rubygems_deps_env)
    allow(config).to receive(:program_path).and_return(program_path)
  end

  let(:program_path) { Pathname('/home/me/.rvm/gems/ruby-2.2.2/bin/guard') }
  let(:rubygems_deps_env) { nil } # or any gemfile path

  context 'when running with bundler' do
    let(:bundle_gemfile_env) { './Gemfile' }

    it 'sets up bundler' do
      expect(config).to receive(:setup_bundler)
      subject.setup
    end
  end

  context 'when not running with bundler' do
    let(:bundle_gemfile_env) { nil }

    context 'when running with rubygems_gemdeps' do
      let(:rubygems_deps_env) { '-' } # or any gemfile path

      it 'sets up rubygems' do
        expect(config).to receive(:setup_rubygems_for_deps)
        subject.setup
      end
    end

    context 'when not running with rubygems_gemdeps' do
      let(:rubygems_deps_env) { nil }

      context 'when running as binstub' do
        let(:program_path) { Pathname('/my/project/bin/guard') }

        context 'when the relative Gemfile exists' do
          before do
            allow(config).to receive(:exist?)
              .with(Pathname('/my/project/Gemfile')).and_return(true)

            allow(config).to receive(:setup_bundler)
            allow(config).to receive(:setup_bundler_env)
          end

          it 'sets up bundler' do
            expect(config).to receive(:setup_bundler)
            subject.setup
          end

          it 'sets the Gemfile' do
            expect(config).to receive(:setup_bundler_env)
              .with('/my/project/Gemfile')
            subject.setup
          end
        end

        context 'when the relative Gemfile does not exist' do
          before do
            allow(config).to receive(:exist?)
              .with(Pathname('/my/project/Gemfile')).and_return(false)

            allow(config).to receive(:exist?).with(Pathname('Gemfile'))
                                             .and_return(false)
          end

          it 'does not setup bundler' do
            subject.setup
          end

          it 'does not setup rubygems' do
            subject.setup
          end

          it 'shows no warning' do
            expect(STDERR).to_not receive(:puts)
            subject.setup
          end
        end
      end

      context 'when not run as binstub' do
        let(:program_path) do
          Pathname('/home/me/.rvm/gems/ruby-2.2.2/bin/guard')
        end

        before do
          allow(config).to receive(:exist?).with(
            Pathname('/home/me/.rvm/gems/ruby-2.2.2/Gemfile')
          ).and_return(false)
        end

        context 'when Gemfile exists' do
          before do
            allow(config).to receive(:exist?).with(Pathname('Gemfile'))
                                             .and_return(true)
          end

          it 'shows a warning' do
            expect(STDERR).to receive(:puts).with(/Warning: you have a Gemfile/)
            subject.setup
          end
        end

        context 'when no Gemfile exists' do
          before do
            allow(config).to receive(:exist?).with(Pathname('Gemfile'))
                                             .and_return(false)
          end

          it 'shows no warning' do
            expect(STDERR).to_not receive(:puts)
            subject.setup
          end
        end
      end
    end
  end
end
