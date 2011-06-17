def mac?
  RbConfig::CONFIG['target_os'] =~ /darwin/i
end

def linux?
  RbConfig::CONFIG['target_os'] =~ /linux/i
end

if linux?
  def command_exists?(c)
    `which #{c}`
    $?.to_i == 0
  end
end

def windows?
  RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
end
