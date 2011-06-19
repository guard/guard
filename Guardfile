guard :rspec, :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

require 'guard/guard'

module ::Guard
  class Breaking < ::Guard::Guard
    def run_all
      raise "Fool !"
    end
  end
end

group "exceptional" do
  guard :breaking
end