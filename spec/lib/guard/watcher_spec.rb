require 'spec_helper'
require 'guard/plugin'

describe Guard::Watcher do

  describe "#initialize" do
    it "requires a pattern parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    context "with a pattern parameter" do
      context "that is a string" do
        it "keeps the string pattern unmodified" do
          expect(described_class.new('spec_helper.rb').pattern).to eq 'spec_helper.rb'
        end
      end

      context "that is a regexp" do
        it "keeps the regex pattern unmodified" do
          expect(described_class.new(/spec_helper\.rb/).pattern).to eq /spec_helper\.rb/
        end
      end

      context "that is a string looking like a regex (deprecated)" do
        before(:each) { Guard::UI.stub(:info) }

        it "converts the string automatically to a regex" do
          expect(described_class.new('^spec_helper.rb').pattern).to eq(/^spec_helper.rb/)
          expect(described_class.new('spec_helper.rb$').pattern).to eq(/spec_helper.rb$/)
          expect(described_class.new('spec_helper\.rb').pattern).to eq(/spec_helper\.rb/)
          expect(described_class.new('.*_spec.rb').pattern).to eq(/.*_spec.rb/)
        end
      end
    end
  end

  describe "#action" do
    it "sets the action to nothing by default" do
      expect(described_class.new(/spec_helper\.rb/).action).to be_nil
    end

    it "sets the action to the supplied block" do
      action = lambda { |m| "spec/#{m[1]}_spec.rb" }
      expect(described_class.new(%r{^lib/(.*).rb}, action).action).to eq action
    end
  end

  describe ".match_files" do
    before(:all) do
      @guard_plugin = Guard::Plugin.new
      @guard_plugin_any_return = Guard::Plugin.new
      @guard_plugin_any_return.options[:any_return] = true
    end

    context "with a watcher without action" do
      context "that is a regex pattern" do
        before(:all) { @guard_plugin.watchers = [described_class.new(/.*_spec\.rb/)] }

        it "returns the paths that matches the regex" do
          expect(described_class.match_files(@guard_plugin, ['guard_rocks_spec.rb', 'guard_rocks.rb'])).to eq ['guard_rocks_spec.rb']
        end
      end

      context "that is a string pattern" do
        before(:all) { @guard_plugin.watchers = [described_class.new('guard_rocks_spec.rb')] }

        it "returns the path that matches the string" do
          expect(described_class.match_files(@guard_plugin, ['guard_rocks_spec.rb', 'guard_rocks.rb'])).to eq ['guard_rocks_spec.rb']
        end
      end
    end

    context "with a watcher action without parameter" do
      context "for a watcher that matches file strings" do
        before(:all) do
          @guard_plugin.watchers = [
            described_class.new('spec_helper.rb', lambda { 'spec' }),
            described_class.new('addition.rb',    lambda { 1 + 1 }),
            described_class.new('hash.rb',        lambda { Hash[:foo, 'bar'] }),
            described_class.new('array.rb',       lambda { ['foo', 'bar'] }),
            described_class.new('blank.rb',       lambda { '' }),
            described_class.new(/^uptime\.rb/,    lambda { `uptime > #{ DEV_NULL }` })
          ]
        end

        it "returns a single file specified within the action" do
          expect(described_class.match_files(@guard_plugin, ['spec_helper.rb'])).to eq ['spec']
        end

        it "returns multiple files specified within the action" do
          expect(described_class.match_files(@guard_plugin, ['hash.rb'])).to eq ['foo', 'bar']
        end

        it "returns multiple files by combining the results of different actions" do
          expect(described_class.match_files(@guard_plugin, ['spec_helper.rb', 'array.rb'])).to eq ['spec', 'foo', 'bar']
        end

        it "returns nothing if the action returns something other than a string or an array of strings" do
          expect(described_class.match_files(@guard_plugin, ['addition.rb'])).to eq []
        end

        it "returns nothing if the action response is empty" do
          expect(described_class.match_files(@guard_plugin, ['blank.rb'])).to eq []
        end

        it "returns nothing if the action returns nothing" do
          expect(described_class.match_files(@guard_plugin, ['uptime.rb'])).to eq []
        end
      end

      context 'for a watcher that matches information objects' do
        before(:all) do
          @guard_plugin_any_return.watchers = [
            described_class.new('spec_helper.rb', lambda { 'spec' }),
            described_class.new('addition.rb',    lambda { 1 + 1 }),
            described_class.new('hash.rb',        lambda { Hash[:foo, 'bar'] }),
            described_class.new('array.rb',       lambda { ['foo', 'bar'] }),
            described_class.new('blank.rb',       lambda { '' }),
            described_class.new(/^uptime\.rb/,    lambda { `uptime > #{ DEV_NULL }` })
          ]
        end

        it "returns a single file specified within the action" do
          expect(described_class.match_files(@guard_plugin_any_return, ['spec_helper.rb']).class).to be Array
          expect(described_class.match_files(@guard_plugin_any_return, ['spec_helper.rb']).empty?).to be_falsey
        end

        it "returns multiple files specified within the action" do
          expect(described_class.match_files(@guard_plugin_any_return, ['hash.rb'])).to eq [{foo: 'bar'}]
        end

        it "returns multiple files by combining the results of different actions" do
          expect(described_class.match_files(@guard_plugin_any_return, ['spec_helper.rb', 'array.rb'])).to eq ['spec', ['foo', 'bar']]
        end

        it "returns the evaluated addition argument in an array" do
          expect(described_class.match_files(@guard_plugin_any_return, ['addition.rb']).class).to be Array
          expect(described_class.match_files(@guard_plugin_any_return, ['addition.rb'])[0]).to eq 2
        end

        it "returns nothing if the action response is empty string" do
          expect(described_class.match_files(@guard_plugin_any_return, ['blank.rb'])).to eq ['']
        end

        it "returns nothing if the action returns is DEV_NULL" do
          expect(described_class.match_files(@guard_plugin_any_return, ['uptime.rb'])).to eq [nil]
        end
      end
    end

    context "with a watcher action that takes a parameter" do
      context "for a watcher that matches file strings" do
         before(:all) do
           @guard_plugin.watchers = [
             described_class.new(%r{lib/(.*)\.rb},   lambda { |m| "spec/#{m[1]}_spec.rb" }),
             described_class.new(/addition(.*)\.rb/, lambda { |m| 1 + 1 }),
             described_class.new('hash.rb',          lambda { |m| Hash[:foo, 'bar'] }),
             described_class.new(/array(.*)\.rb/,    lambda { |m| ['foo', 'bar'] }),
             described_class.new(/blank(.*)\.rb/,    lambda { |m| '' }),
             described_class.new(/uptime(.*)\.rb/,   lambda { |m| `uptime > #{ DEV_NULL }` })
           ]
         end

         it "returns a substituted single file specified within the action" do
           expect(described_class.match_files(@guard_plugin, ['lib/my_wonderful_lib.rb'])).to eq ['spec/my_wonderful_lib_spec.rb']
         end

         it "returns multiple files specified within the action" do
           expect(described_class.match_files(@guard_plugin, ['hash.rb'])).to eq ['foo', 'bar']
         end

         it "returns multiple files by combining the results of different actions" do
           expect(described_class.match_files(@guard_plugin, ['lib/my_wonderful_lib.rb', 'array.rb'])).to eq ['spec/my_wonderful_lib_spec.rb', 'foo', 'bar']
         end

         it "returns nothing if the action returns something other than a string or an array of strings" do
           expect(described_class.match_files(@guard_plugin, ['addition.rb'])).to eq []
         end

         it "returns nothing if the action response is empty" do
           expect(described_class.match_files(@guard_plugin, ['blank.rb'])).to eq []
         end

         it "returns nothing if the action returns nothing" do
           expect(described_class.match_files(@guard_plugin, ['uptime.rb'])).to eq []
         end
      end

      context "for a watcher that matches information objects" do
        before(:all) do
          @guard_plugin_any_return.watchers = [
            described_class.new(%r{lib/(.*)\.rb},   lambda { |m| "spec/#{m[1]}_spec.rb" }),
            described_class.new(/addition(.*)\.rb/, lambda { |m| (1 + 1).to_s + m[0] }),
            described_class.new('hash.rb',          lambda { |m| Hash[:foo, 'bar', :file_name, m[0]] }),
            described_class.new(/array(.*)\.rb/,    lambda { |m| ['foo', 'bar', m[0]] }),
            described_class.new(/blank(.*)\.rb/,    lambda { |m| '' }),
            described_class.new(/uptime(.*)\.rb/,   lambda { |m| `uptime > #{ DEV_NULL }` })
          ]
        end

        it "returns a substituted single file specified within the action" do
          expect(described_class.match_files(@guard_plugin_any_return, ['lib/my_wonderful_lib.rb'])).to eq ['spec/my_wonderful_lib_spec.rb']
        end

        it "returns a hash specified within the action" do
          expect(described_class.match_files(@guard_plugin_any_return, ['hash.rb'])).to eq [{foo: 'bar', file_name: 'hash.rb'}]
        end

        it "returns multiple files by combining the results of different actions" do
          expect(described_class.match_files(@guard_plugin_any_return, ['lib/my_wonderful_lib.rb', 'array.rb'])).to eq ['spec/my_wonderful_lib_spec.rb', ['foo', 'bar', "array.rb"]]
        end

        it "returns the evaluated addition argument + the path" do
          expect(described_class.match_files(@guard_plugin_any_return, ['addition.rb'])).to eq ["2addition.rb"]
        end

        it "returns nothing if the action response is empty string" do
          expect(described_class.match_files(@guard_plugin_any_return, ['blank.rb'])).to eq ['']
        end

        it "returns nothing if the action returns is DEV_NULL" do
          expect(described_class.match_files(@guard_plugin_any_return, ['uptime.rb'])).to eq [nil]
        end
      end
    end

    context "with an exception that is raised" do
       before(:all) { @guard_plugin.watchers = [described_class.new('evil.rb', lambda { raise "EVIL" })] }

       it "displays the error and backtrace" do
         expect(Guard::UI).to receive(:error) do |msg|
           expect(msg).to include("Problem with watch action!")
           expect(msg).to include("EVIL")
         end

         described_class.match_files(@guard_plugin, ['evil.rb'])
       end
     end
   end

  describe ".match_files?" do
    before(:all) do
      @guard1 = Guard::Plugin.new(watchers: [described_class.new(/.*_spec\.rb/)])
      @guard2 = Guard::Plugin.new(watchers: [described_class.new('spec_helper.rb', 'spec')])
      @plugins = [@guard1, @guard2]
    end

    context "with a watcher that matches a file" do
      specify { expect(described_class.match_files?(@plugins, ['lib/my_wonderful_lib.rb', 'guard_rocks_spec.rb'])).to be_truthy }
    end

    context "with no watcher that matches a file" do
      specify { expect(described_class.match_files?(@plugins, ['lib/my_wonderful_lib.rb'])).to be_falsey }
    end
  end

  describe ".match" do
    context "with a string pattern" do
      context "that is a normal string" do
        subject { described_class.new('guard_rocks_spec.rb') }

        context "with a watcher that matches a file" do
          specify { expect(subject.match('guard_rocks_spec.rb')).to eq ['guard_rocks_spec.rb'] }
        end

        context "with a file containing a $" do
          subject { described_class.new('lib$/guard_rocks_spec.rb') }

          specify { expect(subject.match('lib$/guard_rocks_spec.rb')).to eq ['lib$/guard_rocks_spec.rb'] }
        end

        context "with no watcher that matches a file" do
          specify { expect(subject.match('lib/my_wonderful_lib.rb')).to be_nil }
        end
      end

      context "that is a string representing a regexp (deprecated)" do
        subject { described_class.new('^guard_(rocks)_spec\.rb$') }

        context "with a watcher that matches a file" do
          specify { expect(subject.match('guard_rocks_spec.rb')).to eq ['guard_rocks_spec.rb', 'rocks'] }
        end

        context "with no watcher that matches a file" do
          specify { expect(subject.match('lib/my_wonderful_lib.rb')).to be_nil }
        end
      end
    end

    context "with a regexp pattern" do
      subject { described_class.new(/(.*)_spec\.rb/) }

      context "with a watcher that matches a file" do
        specify { expect(subject.match('guard_rocks_spec.rb')).to eq ['guard_rocks_spec.rb', 'guard_rocks'] }
      end

      context "with a file containing a $" do
        specify { expect(subject.match('lib$/guard_rocks_spec.rb')).to eq ['lib$/guard_rocks_spec.rb', 'lib$/guard_rocks'] }
      end

      context "with no watcher that matches a file" do
        specify { expect(subject.match('lib/my_wonderful_lib.rb')).to be_nil }
      end
    end

    context "path start with a !" do
      context "with a string pattern" do
        subject { described_class.new('guard_rocks_spec.rb') }

        context "with a watcher that matches a file" do
          specify { expect(subject.match('!guard_rocks_spec.rb')).to eq ['!guard_rocks_spec.rb'] }
        end

        context "with no watcher that matches a file" do
          specify { expect(subject.match('!lib/my_wonderful_lib.rb')).to be_nil }
        end
      end

      context "with a regexp pattern" do
        subject { described_class.new(/(.*)_spec\.rb/) }

        context "with a watcher that matches a file" do
          specify { expect(subject.match('!guard_rocks_spec.rb')).to eq ['!guard_rocks_spec.rb', 'guard_rocks'] }
        end

        context "with no watcher that matches a file" do
          specify { expect(subject.match('!lib/my_wonderful_lib.rb')).to be_nil }
        end
      end
    end
  end

  describe '.match_guardfile?' do
    before { Guard.stub(:evaluator) { double(guardfile_path: File.expand_path('Guardfile')) } }

    context "with files that match the Guardfile" do
      specify { expect(described_class.match_guardfile?(['Guardfile', 'guard_rocks_spec.rb'])).to be_truthy }
    end

    context "with no files that match the Guardfile" do
      specify { expect(described_class.match_guardfile?(['guard_rocks.rb', 'guard_rocks_spec.rb'])).to be_falsey }
    end
  end

end
