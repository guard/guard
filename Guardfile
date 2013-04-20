scope :group => :specs

group :specs do
  guard :rspec, :keep_failed => false, :cli => '--fail-fast --format doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('lib/guard/notifier.rb')           { 'spec/guard/notifiers' }
    watch('lib/guard/interactor.rb')         { 'spec/guard/commands' }
    watch(%r{^lib/guard/(guard|plugin).rb$}) { 'spec/guard/plugin' }
    watch('spec/spec_helper.rb')             { 'spec' }
  end
end

group :docs do
  guard :ronn do
    watch(%r{^man/.+\.ronn?$})
  end
end
