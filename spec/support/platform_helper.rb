def mac?
  Config::CONFIG['target_os'] =~ /darwin/i
end

def linux?
  Config::CONFIG['target_os'] =~ /linux/i
end

if linux?
  def command_exists?(c)
    `which #{c}`
    $?.to_i == 0
  end
end

def windows?
  Config::CONFIG['target_os'] =~ /mswin|mingw/i
end