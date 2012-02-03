# vim: fileencoding=UTF-8 nobomb sw=2 ts=2 et

XCODEBUILD = '/usr/bin/xcodebuild'
XCCONFIG = File.expand_path('rb-fsevent.xcconfig')

namespace :xcode do
  $target = 'fsevent_watch'
  $configuration = ENV['FWDEBUG'] ? 'Debug' : 'Release'
    
  def xcb(action, extra='')
    command = [
      XCODEBUILD,
      "-target", $target,
      "-configuration", $configuration,
      action,
      "-xcconfig", XCCONFIG,
      extra
    ].join(' ')
    
    Dir.chdir 'fsevent_watch' do
      results = `#{command}`
      STDERR.puts results
      raise "xcodebuild failure" unless $?.success?
    end
  end
  
  desc 'run xcodebuild clean'
  task :clean do
    xcb 'clean'
  end
  
  desc 'run xcodebuild build'
  task :build => :clean do
    xcb 'build'
  end
  
  desc 'run xcodebuild install'
  task :install => :build do
    xcb 'install', "DEPLOYMENT_LOCATION='YES'"
  end
  
  task :remove_turds do
    rm_rf File.join('fsevent_watch', 'build')
  end
end

task :default => ['xcode:install', 'xcode:remove_turds']
