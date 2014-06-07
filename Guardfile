group :specs do
  guard :rspec, cmd: 'bundle exec rspec', failed_mode: :keep do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^(lib/.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('lib/guard/notifier.rb')           { 'spec/guard/notifiers' }
    watch('lib/guard/interactor.rb')         { 'spec/guard/commands' }
    watch(%r{^lib/guard/(guard|plugin).rb$}) { 'spec/guard/plugin' }
    watch('spec/spec_helper.rb')             { 'spec' }
  end

  guard :rubocop, all_on_start: false, cli: '--rails' do
    watch(%r{.+\.rb$}) { |m| m[0] }
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end


if ENV['CI'] != 'true'
  group :docs do
    guard :ronn do
      watch(%r{^man/.+\.ronn?$})
    end
  end
end
