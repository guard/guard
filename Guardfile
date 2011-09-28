group :specs do
  guard :rspec, :cli => '--format doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})                { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/support/listener_helper.rb') { Dir.glob("spec/guard/listeners/*") }
    watch('spec/spec_helper.rb')             { "spec" }
  end
end

group :docs do
  guard :ronn do
    watch(%r{^man/.+\.ronn?$})
  end
end

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
