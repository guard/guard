def mac?
  Config::CONFIG['target_os'] =~ /darwin/i
end

def linux?
  Config::CONFIG['target_os'] =~ /linux/i
end

def windows?
  Config::CONFIG['target_os'] =~ /mswin|mingw/i
end
