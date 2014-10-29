require "aruba"
require "aruba/cucumber"

require "aruba/in_process"
require "guard/aruba_adapter"

Aruba::InProcess.main_class = Guard::ArubaAdapter
Aruba::process = Aruba::InProcess
