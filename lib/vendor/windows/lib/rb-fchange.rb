require "rb-fchange/native"
require "rb-fchange/native/flags"
require "rb-fchange/notifier"
require "rb-fchange/watcher"
require "rb-fchange/event"

# The root module of the library, which is laid out as so:
#
# * {Notifier} -- The main class, where the notifications are set up
# * {Watcher} -- A watcher for a single file or directory
# * {Event} -- An filesystem event notification
module FChange

end