def growl_installed?
  require 'growl'
  true
rescue LoadError
  false
end

def libnotify_installed?
  require 'libnotify'
  true
rescue LoadError
  false
end