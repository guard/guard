# rb-fchange

Code is working. But there is still a lot of work.
This is a simple wrapper over the Windows Kernel functions for monitoring the specified directory or subtree.
Tested on:

 - jruby 1.6.1 (ruby-1.8.7-p330) (2011-04-12 85838f6)
 - ruby 1.8.7 (2011-02-18 patchlevel 334) [i386-ingw32]
 - ruby 1.9.2p180 (2011-02-18) [i386-mingw32]

Example

```ruby
  require 'rb-fchange'
  
  notifier = FChange::Notifier.new
  notifier.watch("test", :all_events, :recursive) do |event|
    p Time.now.utc
  end
  
  Signal.trap('INT') do
    p "Bye bye...",
    notifier.stop
    abort("\n")
  end
  
  notifier.run
```

## TODO

 - add latency setting with 0.5 default
 - rework interface (should more look like rb-fsevent)
 - add none-ANSI path support
