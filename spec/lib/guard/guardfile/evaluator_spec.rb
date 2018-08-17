# frozen_string_literal: true

require 'guard/guardfile/evaluator'

# TODO: shouldn't be necessary
require 'guard'

RSpec.describe Guard::Guardfile::Evaluator do
  let(:options) { {} }
  subject { described_class.new(options) }

  let!(:local_guardfile) { (Pathname.pwd + 'Guardfile').to_s }
  let!(:home_guardfile) { (Pathname('~').expand_path + '.Guardfile').to_s }
  let!(:home_config) { (Pathname('~').expand_path + '.guard.rb').to_s }

  let(:valid_guardfile_string) { 'group :foo; do guard :bar; end; end; ' }

  let(:dsl) { instance_double('Guard::Dsl') }

  let(:rel_guardfile) do
    Pathname('../relative_path_to_Guardfile').expand_path.to_s
  end

  before do
    allow(Guard::Interactor).to receive(:new).with(false)
    allow(Guard::Dsl).to receive(:new).and_return(dsl)
    allow(dsl).to receive(:instance_eval)
  end

  describe '.evaluate' do
    describe 'error cases' do
      context 'with an invalid Guardfile' do
        let(:options) { { contents: 'guard :foo Bad Guardfile' } }

        it 'displays an error message and raises original exception' do
          stub_user_guard_rb

          allow(dsl).to receive(:evaluate)
            .and_raise(Guard::Dsl::Error,
                      'Invalid Guardfile, original error is:')

          expect { subject.evaluate }.to raise_error(Guard::Dsl::Error)
        end
      end

      context 'with no Guardfile at all' do
        it 'displays an error message and exits' do
          stub_guardfile
          stub_user_guardfile
          stub_user_project_guardfile

          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoGuardfileError)
        end
      end

      context 'with a problem reading a Guardfile' do
        let(:path) { File.expand_path('Guardfile') }

        before do
          stub_user_project_guardfile
          stub_guardfile(' ') do
            fail Errno::EACCES.new('permission error')
          end
        end

        it 'displays an error message and exits' do
          expect(Guard::UI).to receive(:error).with(/^Error reading file/)
          expect { subject.evaluate }.to raise_error(SystemExit)
        end
      end

      context 'with empty Guardfile content' do
        let(:options) { { contents: '' } }

        it 'displays an error message about no plugins' do
          stub_user_guard_rb
          stub_guardfile(' ')
          allow(dsl).to receive(:evaluate).with('', '', 1)

          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoPluginsError)
        end
      end

      context 'when provided :contents is nil' do
        before do
          # Anything
          stub_guardfile('guard :foo')

          stub_user_guard_rb
          stub_user_project_guardfile
          stub_user_guardfile
        end

        it 'does not raise error and skip it' do
          allow(dsl).to receive(:evaluate).with('guard :foo', anything, 1)

          expect(Guard::UI).to_not receive(:error)
          expect do
            described_class.new(contents: nil).evaluate
          end.to_not raise_error
        end
      end

      context 'with a non-existing Guardfile given' do
        let(:non_existing_path) { '/non/existing/path/to/Guardfile' }
        let(:options) { { guardfile: non_existing_path } }

        before do
          stub_file(non_existing_path)
        end

        it 'raises error' do
          expect { subject.evaluate }
            .to raise_error(Guard::Guardfile::Evaluator::NoCustomGuardfile)
        end
      end
    end

    describe 'selection of the Guardfile data contents' do
      context 'with a valid :contents option' do
        before do
          stub_user_guard_rb
          allow(dsl).to receive(:evaluate)
        end

        context 'with inline content and other Guardfiles available' do
          let(:inline_code) { 'guard :foo' }
          let(:options) do
            {
              contents: inline_code,
              guardfile: '/abc/Guardfile'
            }
          end

          before do
            stub_file('/abc/Guardfile', 'guard :bar')
            stub_guardfile('guard :baz')
            stub_user_guardfile('guard :buz')
          end

          it 'gives ultimate precedence to inline content' do
            expect(dsl).to receive(:evaluate).with(inline_code, '', 1)
            subject.evaluate
          end
        end
      end

      context 'with the :guardfile option' do
        let(:options) { { guardfile: '../relative_path_to_Guardfile' } }

        before do
          stub_file(File.expand_path('../relative_path_to_Guardfile'),
                    valid_guardfile_string)
          allow(dsl).to receive(:evaluate)
            .with(valid_guardfile_string, anything, 1)
        end
      end
    end
  end

  describe '#inline?' do
    before do
      allow(dsl).to receive(:evaluate)
      stub_guardfile('guard :bar')
      stub_user_guard_rb
      subject.evaluate
    end

    context 'when content is provided' do
      let(:options) { { guardfile_contents: 'guard :foo' } }
      it { is_expected.to be_inline }
    end

    context 'when no content is provided' do
      let(:options) { {} }
      it { is_expected.to_not be_inline }
    end
  end

  describe '.guardfile_include?' do
    subject do
      evaluator = described_class.new(options)
      evaluator.evaluate
      evaluator
    end

    let(:dsl_reader) { instance_double(Guard::DslReader) }

    before do
      allow(dsl).to receive(:evaluate)
      allow(Guard::DslReader).to receive(:new).and_return(dsl_reader)
      allow(dsl_reader).to receive(:evaluate)
      stub_user_guard_rb
    end

    context 'when plugin is present' do
      let(:options) { { contents: 'guard "test" {watch("c")}' } }

      it 'returns true' do
        allow(dsl_reader)
          .to receive(:evaluate).with('guard "test" {watch("c")}', '', 1)

        allow(dsl_reader).to receive(:plugin_names).and_return(['test'])
        expect(subject).to be_guardfile_include('test')
      end
    end

    context 'when plugin is not present' do
      let(:options) { { contents: 'guard "other" {watch("c")}' } }

      it 'returns false' do
        allow(dsl_reader)
          .to receive(:evaluate).with('guard "test" {watch("c")}', '', 1)

        allow(dsl_reader).to receive(:plugin_names).and_return(['other'])
        expect(subject).to_not be_guardfile_include('test')
      end
    end
  end
end
