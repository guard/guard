# guard 'spork', :rspec_port => 9010 do
#   watch('^config/initializers/.*')
# end

def super
  `say yo`
end

guard 'rspec', :version => 2 do
  watch('^spec/(.*)_spec.rb')
  watch('^lib/(.*).rb')                               { |m| "spec/#{m[1]}_spec.rb" }
  watch('^spec/spec_helper.rb')                       { "spec" }
  # watch('^spec/spec_helper.rb')                       { `say hello` }
  # watch('^spec/(.*)_spec\.rb')
  # watch('^app/(.*)\.rb')                               { |m| "spec/#{m[1]}_spec.rb" }
  # watch('^app/(.*)\.html.erb')                         { |m| "spec/#{m[1]}_spec.rb" }
  # watch('^lib/(.*)\.rb')                               { |m| "spec/lib/#{m[1]}_spec.rb" }
  # watch('^spec/spec_helper\.rb')                       { |m| "spec" }
  # watch('^config/routes\.rb')                          { |m| "spec/routing" }
  # watch('^spec/factories\.rb')                         { |m| "spec/model" }
  # watch('^app/controllers/application_controller\.rb') { |m| "spec/controllers" }
end

# guard 'livereload' do
# end