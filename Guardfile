group :specs do
  guard :rspec, cmd: 'bundle exec rspec --fail-fast -f doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^(lib/.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('lib/guard/notifier.rb')           { 'spec/guard/notifiers' }
    watch('lib/guard/interactor.rb')         { 'spec/guard/commands' }
    watch(%r{^lib/guard/(guard|plugin).rb$}) { 'spec/guard/plugin' }
    watch('spec/spec_helper.rb')             { 'spec' }
  end
end

if ENV['CI'] != 'true'
  group :docs do
    guard :ronn do
      watch(%r{^man/.+\.ronn?$})
    end
  end
end
