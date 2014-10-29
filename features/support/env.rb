require "aruba"
require "aruba/cucumber"

require "aruba/in_process"
require "guard/aruba_adapter"

Aruba::InProcess.main_class = Guard::ArubaAdapter
Aruba::process = Aruba::InProcess

Before do
  set_env "HOME", File.expand_path(File.join(current_dir, "home"))
  FileUtils.mkdir_p ENV["HOME"]
end
