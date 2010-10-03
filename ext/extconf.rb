# Workaround to make Rubygems believe it builds a native gem
require 'mkmf'
create_makefile('none')

if `uname -s`.chomp == 'Darwin'
  gem_root      = File.expand_path(File.join('..'))
  darwin_verion = `uname -r`.to_i
  sdk_verion    = { 9 => '10.5', 10 => '10.6', 11 => '10.7' }[darwin_verion]
  
  raise "Darwin #{darwin_verion} is not supported" unless sdk_verion
  
  # Compile the actual fsevent_watch binary
  system("CFLAGS='-isysroot /Developer/SDKs/MacOSX#{sdk_verion}.sdk -mmacosx-version-min=#{sdk_verion}' /usr/bin/gcc -framework CoreServices -o '#{gem_root}/bin/fsevent_watch' fsevent/fsevent_watch.c")
  
  unless File.executable?("#{gem_root}/bin/fsevent_watch")
    raise "Compilation of fsevent_watch failed (see README)"
  end
end
