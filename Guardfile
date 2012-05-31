group :specs do
  guard :rspec, :all_on_start => false, :all_after_pass => false, :cli => '--fail-fast --format doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')             { "spec" }
  end
end

# group :docs do
#   guard :ronn do
#     watch(%r{^man/.+\.ronn?$})
#   end
# end

# require 'guard/guard'
#
# module ::Guard
#   class Breaking < ::Guard::Guard
#     def run_all
#       raise "Fool !"
#     end
#   end
# end
#
# group "exceptional" do
#   guard :breaking
# end
