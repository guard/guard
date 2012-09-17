group :specs do
  guard :rspec, :cli => '--fail-fast --format doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')             { "spec" }
  end
end

#group :docs do
#  guard :ronn do
#    watch(%r{^man/.+\.ronn?$})
#  end
#end
