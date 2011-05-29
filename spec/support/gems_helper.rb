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

def rbnotifu_installed?
  require 'rb-notifu'
  true
rescue LoadError
  false
end