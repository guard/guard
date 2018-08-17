# frozen_string_literal: true

require 'guard/internals/scope'

RSpec.describe Guard::Internals::Scope do
  let(:session) { instance_double('Guard::Internals::Session') }
  let(:state) { instance_double('Guard::Internals::State') }

  let(:groups) { instance_double('Guard::Internals::Groups') }
  let(:plugins) { instance_double('Guard::Internals::Plugins') }

  let(:foo_plugin) { instance_double('Guard::Plugin', name: :foo) }
  let(:bar_plugin) { instance_double('Guard::Plugin', name: :bar) }
  let(:baz_plugin) { instance_double('Guard::Plugin', name: :baz) }

  let(:foo_group) { instance_double('Guard::Group', name: :foo) }
  let(:bar_group) { instance_double('Guard::Group', name: :bar) }
  let(:baz_group) { instance_double('Guard::Group', name: :baz) }

  before do
    allow(groups).to receive(:all).with('foo').and_return([foo_group])
    allow(groups).to receive(:all).with('bar').and_return([bar_group])
    allow(groups).to receive(:all).with('baz').and_return([baz_group])
    allow(groups).to receive(:all).with(:baz).and_return([baz_group])

    allow(plugins).to receive(:all).with('foo').and_return([foo_plugin])
    allow(plugins).to receive(:all).with('bar').and_return([bar_plugin])
    allow(plugins).to receive(:all).with('baz').and_return([baz_plugin])
    allow(plugins).to receive(:all).with(:baz).and_return([baz_plugin])

    allow(session).to receive(:cmdline_plugins).and_return([])
    allow(session).to receive(:cmdline_groups).and_return([])
    allow(session).to receive(:groups).and_return(groups)
    allow(session).to receive(:plugins).and_return(plugins)

    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(session).to receive(:guardfile_plugin_scope).and_return([])
    allow(session).to receive(:guardfile_group_scope).and_return([])
  end

  # TODO: move to Session?
  describe '#to_hash' do
    %i[group plugin].each do |scope|
      describe scope.inspect do
        let(:hash) do
          subject.to_hash[:"#{scope}s"].map(&:name).map(&:to_s)
        end

        # NOTE: interactor returns objects
        context 'when set from interactor' do
          before do
            stub_obj = send("baz_#{scope}")
            subject.from_interactor(:"#{scope}s" => stub_obj)
          end

          it 'uses interactor scope' do
            expect(hash).to contain_exactly('baz')
          end
        end

        context 'when not set in interactor' do
          context 'when set in commandline' do
            before do
              allow(session).to receive(:"cmdline_#{scope}s")
                .and_return(%w[baz])
            end

            it 'uses commandline scope' do
              expect(hash).to contain_exactly('baz')
            end
          end

          context 'when not set in commandline' do
            context 'when set in Guardfile' do
              before do
                allow(session).to receive(:"guardfile_#{scope}_scope")
                  .and_return(%w[baz])
              end

              it 'uses guardfile scope' do
                expect(hash).to contain_exactly('baz')
              end
            end
          end
        end
      end
    end
  end

  describe '#titles' do
    pending
  end
end
