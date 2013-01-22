Guard [![Gem Version](https://badge.fury.io/rb/guard.png)](http://badge.fury.io/rb/guard) [![Build Status](https://secure.travis-ci.org/guard/guard.png?branch=master)](http://travis-ci.org/guard/guard) [![Dependency Status](https://gemnasium.com/guard/guard.png)](https://gemnasium.com/guard/guard) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/guard/guard)
=====

Guard is a command line tool to easily handle events on file system modifications.

This document contains a lot of information, please take your time and read these instructions carefully. If you have
any questions, ask them in our [Google group](http://groups.google.com/group/guard-dev) or on `#guard`
(irc.freenode.net).

Information on advanced topics like creating your own Guard plugin, programatic use of Guard, hooks and callbacks and
more can be found in the [Guard wiki](https://github.com/guard/guard/wiki).

Before you file an issue, make sure you have read the _[file an issue](#file-an-issue)_ section that contains some
important information.

Features
--------

* File system changes handled by our awesome [Listen](https://github.com/guard/listen) gem.
* Support for visual system notifications.
* Huge eco-system with [more than 150](https://rubygems.org/search?query=guard-) guard plugins.
* Tested against Ruby 1.8.7, 1.9.2, 1.9.3, REE and the latest versions of JRuby & Rubinius.

Screencast
----------

Ryan Bates made an excellent [RailsCast about Guard](http://railscasts.com/episodes/264-guard) and you should definitely
watch it for a nice introduction to Guard.

Installation
------------

The simplest way to install Guard is to use [Bundler](http://gembundler.com/).

Add Guard to your `Gemfile`:

```ruby
group :development do
  gem 'guard'
end
```

and install it by running Bundler:

```bash
$ bundle
```

Generate an empty `Guardfile` with:

```bash
$ guard init
```

**It's important that you always run Guard through Bundler to avoid errors.** If you're getting sick of typing
`bundle exec` all the time, try the [Rubygems Bundler](https://github.com/mpapis/rubygems-bundler).

If you are on Mac OS X and have problems with either Guard not reacting to file changes or Pry behaving strange, then
you should [add proper Readline support to Ruby on Mac OS X](https://github.com/guard/guard/wiki/Add-proper-Readline-support-to-Ruby-on-Mac-OS-X).

## Efficient Filesystem Handling

Various operating systems are willing to notify you of changes to files, but the API to register/receive updates varies
(see [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) for OS X, [rb-inotify](https://github.com/nex3/rb-inotify)
for Linux, and [rb-fchange](https://github.com/stereobooster/rb-fchange) for Windows). If you do not supply one of the
supported gems for these methods, Guard will fall back to polling, and give you a warning about it doing so.

A challenge arises when trying to make these dependencies work with [Bundler](http://gembundler.com/). If you simply put
one of these dependencies into you `Gemfile`, even if it is conditional on a platform match, the platform-specific gem
will end up in the `Gemfile.lock`, and developers will thrash the file back and forth.

There is a good solution. All three gems will successfully, quietly install on all three operating systems, and
`guard/listen` will only pull in the one you need. This is a more proper `Gemfile`:

```Ruby
group :development do
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end
```

If you're using Windows and at least Ruby 1.9.2, then [Windows Directory Monitor](https://github.com/Maher4Ever/wdm) is
more efficient than using `rb-fchange`.

```Ruby
group :development do
  gem 'wdm', :platforms => [:mswin, :mingw], :require => false
end
```

## Windows Colors

If you want colors in your terminal, you'll have to add the [win32console](https://rubygems.org/gems/win32console) gem
to your `Gemfile` and install it with Bundler:

```ruby
group :development do
  gem 'win32console'
end
```

## System notifications

You can configure Guard to make use of the following system notification libraries:

#### Ruby GNTP

* Runs on Mac OS X, Linux and Windows
* Supports [Growl](http://growl.info/) version >= 1.3, [Growl for Linux](http://mattn.github.com/growl-for-linux/),
  [Growl for Windows](http://www.growlforwindows.com/gfw/default.aspx) and
  [Snarl](https://sites.google.com/site/snarlapp/home)

The [ruby_gntp](https://rubygems.org/gems/ruby_gntp) gem sends system notifications over the network with the
[Growl Notification Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx) and supports local and
remote notifications. To have the images be displayed, you have to use `127.0.0.1` instead of `localhost` in your GTNP
configuration.

Guard supports multiple notification channels for customizing each notification type. For Growl on Mac OS X you need
to have at least version 1.3 installed.

To use `ruby_gntp` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'ruby_gntp'
end
```

#### Growl

* Runs on Mac OS X
* Supports all [Growl](http://growl.info/) versions

The [growl](https://rubygems.org/gems/growl) gem is compatible with all versions of Growl and uses a command line tool
[growlnotify](http://growl.info/extras.php#growlnotify) that must be separately downloaded and installed. The version of
the command line tool must match your Growl version. The `growl` gem does **not** support multiple notification
channels.

You have to download the installer for `growlnotify` from the [Growl download section](http://growl.info/downloads).

To use `growl` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'growl'
end
```

#### Libnotify

* Runs on Linux, FreeBSD, OpenBSD and Solaris
* Supports [Libnotify](http://developer.gnome.org/libnotify/)

The [libnotify](https://rubygems.org/gems/libnotify) gem supports the Gnome libnotify notification daemon, but it can be
used on other window managers as well. You have to install the `libnotify-bin` package with your favorite package
manager.

To use `libnotify` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'libnotify'
end
```

If you are unable to build the `libnotify` gem on your system, Guard
also has a built in notifier - `notifysend` - that shells out to the
`notify-send` utility that comes with `libnotify-bin`.

#### Notifu

* Runs on Windows
* Supports [Notifu](http://www.paralint.com/projects/notifu/)

The [rb-notifu](https://rubygems.org/gems/rb-notifu) gem supports Windows system tray notifications.

To use `rb-notifu` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'rb-notifu'
end
```

#### GrowlNotify

* Runs on Mac OS X
* Supports [Growl](http://growl.info/) version >= 1.3
* Doesn't support JRuby and MacRuby.
* Doesn't work when forking, e.g. with [Spork](https://github.com/sporkrb/spork).

The [growl_notify](https://rubygems.org/gems/growl_notify) gem uses AppleScript to send Growl notifications.
The gem needs a native C extension to make use of AppleScript and does not run on JRuby and MacRuby.

Guard supports multiple notification channels for customizing each notification type and you need to have at least
Growl version 1.3 installed.

To use `growl_notify` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'growl_notify'
end
```

#### Terminal Notifier

* Runs on Mac OS X 10.8 only

The [terminal-notifier-guard](https://github.com/Springest/terminal-notifier-guard) sends notifications to the OS X
Notification Center.

To use `terminal-notifier-guard` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'terminal-notifier-guard'
end
```

#### Terminal Title

* Runs in every terminal supporting XTerm escape sequences to set the window title.

#### Emacs

* Runs on any platform with Emacs + emacsclient (http://www.emacswiki.org/emacs/EmacsClient)

### TMux

* To use TMux notifications, you have to start Guard within a [TMux](http://tmux.sourceforge.net/) session.

The TMux notifier will color the background of the left part of the
status bar indicating the status of the notifications. Optionally you
can set `:display_message => true` to display the Guard notification as
'display-message' notification.

The way these messages are formatted is configurable.

```ruby
# Guardfile
notification :tmux,
  :display_message => true,
  :timeout => 5, # in seconds
  :default_message_format => '%s >> %s',
  # the first %s will show the title, the second the message
  # Alternately you can also configure *success_message_format*,
  # *pending_message_format*, *failed_message_format*
  :line_separator => ' > ', # since we are single line we need a separator
  :color_location => 'status-left-bg' # to customize which tmux element will change color
```

The result will be for RSpec using example above

    RSpec >> 15 test, 0 failures > in 0.002 sec

You can use nice powerline chars here if you have that configured.

You can get the message history by using `Ctrl+b ~` (where `Ctrl+b` is your key to activate TMux).

Add Guard plugins
-----------------

Guard is now ready to use and you should add some Guard plugins for your specific use. Start exploring the many Guard
plugins available by browsing the [Guard organization](https://github.com/guard) on GitHub or by searching for `guard-`
on [RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=guard-).

When you have found a Guard plugin of your interest, add it to your `Gemfile`:

```ruby
group :development do
  gem '<guard-plugin-name>'
end
```

See the init section of the Guard usage below to see how to install the supplied plugin template that you can install and
to suit your needs.

Usage
-----

Guard is run from the command line. Please open your terminal and go to your project work directory.

### Help

You can always get help on the available tasks with the `help` task:

```bash
$ guard help
```

To request more detailed help on a specific task is simple: just appending the task name to the help task.
For example, to get help for the `start` task, simply run:

```bash
$ guard help start
```

### Init

You can generate a Guardfile and have all installed plugins be automatically added into
it by running the `init` task without any option:

```bash
$ guard init
```

You can also specify the name of an installed plugin to only get that plugin template
in the generated Guardfile:

```bash
$ guard init <guard-name>
```

You can also specify the names of multiple plugins to only get those plugin templates
in the generated Guardfile:

```bash
$ guard init <guard1-name> <guard2-name>
```

You can also define your own templates in `~/.guard/templates/` which can be appended in the same way to your existing
`Guardfile`:

```bash
$ guard init <template-name>
```

**Note**: If you already have a `Guardfile` in the current directory, the `init` task can be used
to append a supplied template from an installed plugin to your existing `Guardfile`.

#### `-b`/`--bare` option

You can generate an empty `Guardfile` by running the `init` task with the bare
option:

```bash
$ guard init --bare
$ guard init -b # shortcut
```

### Start

Just launch Guard inside your Ruby or Rails project with:

```bash
$ guard
```

Guard will look for a `Guardfile` in your current directory. If it does not find one, it will look in your `$HOME`
directory for a `.Guardfile`.

#### `-c`/`--clear` option

The shell can be cleared after each change:

```bash
$ guard --clear
$ guard -c # shortcut
```

You can add the following snippet to your `~/.guardrc` to have the clear option always be enabled:

```
Guard.options[:clear] = true
```

#### `-n`/`--notify` option

System notifications can be disabled:

```bash
$ guard --notify false
$ guard -n f # shortcut
```

Notifications can also be disabled globally by setting a `GUARD_NOTIFY` environment variable to `false`.

#### `-g`/`--group` option

Scope Guard to certain plugin groups on start:

```bash
$ guard --group group_name another_group_name
$ guard -g group_name another_group_name # shortcut
```

See the Guardfile DSL below for creating groups.

#### `-P`/`--plugins` option

Scope Guard to certain plugins on start:

```bash
$ guard --plugins plugin_name another_plugin_name
$ guard -P plugin_name another_plugin_name # shortcut
```

#### `-d`/`--debug` option

Guard can display debug information which can be very usefull for plugins
developers with:

```bash
$ guard --debug
$ guard -d # shortcut
```

#### `-w`/`--watchdir` option

Guard can watch any directory instead of the current directory:

```bash
$ guard --watchdir ~/your/fancy/project
$ guard -w ~/your/fancy/project # shortcut
```

#### `-G`/`--guardfile` option

Guard can use a `Guardfile` not located in the current directory:

```bash
$ guard --guardfile ~/.your_global_guardfile
$ guard -G ~/.your_global_guardfile # shortcut
```

#### `-i`/`--no-interactions` option

Turn off completely any Guard terminal interactions with:

```bash
$ guard start -i
$ guard start --no-interactions
```

#### `-B`/`--no-bundler-warning` option

Skip Bundler warning when a Gemfile exists in the project directory but Guard is not run with Bundler.

```bash
$ guard start -B
$ guard start --no-bundler-warning
```

#### `-l`/`--latency` option

Overwrite Listen's default latency, useful when your hard-drive / system is slow.

```bash
$ guard start -l 1.5
$ guard start --latency 1.5
```

#### `-p`/`--force-polling` option

Force Listen polling listener usage.

```bash
$ guard start -p
$ guard start --force-polling
```

### List

You can list the available plugins with the `list` task:

```bash
$ guard list
+----------+--------------+
| Available Guard plugins |
+----------+--------------+
| Plugin   | In Guardfile |
+----------+--------------+
| Compass  | ✘            |
| Cucumber | ✘            |
| Jammit   | ✘            |
| Ronn     | ✔            |
| Rspec    | ✔            |
| Spork    | ✘            |
| Yard     | ✘            |
+----------+--------------+
```

### Show

You can show the structure of the groups and their plugins with the `show` task:

```bash
$ guard show
+---------+--------+-----------------+----------------------------+
|                       Guardfile structure                       |
+---------+--------+-----------------+----------------------------+
| Group   | Plugin | Option          | Value                      |
+---------+--------+-----------------+----------------------------+
| Default |        |                 |                            |
| Specs   | Rspec  | all_after_pass  | true                       |
|         |        | all_on_start    | true                       |
|         |        | cli             | "--fail-fast --format doc" |
|         |        | focus_on_failed | false                      |
|         |        | keep_failed     | true                       |
|         |        | run_all         | {}                         |
|         |        | spec_paths      | ["spec"]                   |
| Docs    | Ronn   |                 |                            |
+---------+--------+-----------------+----------------------------+
```

This shows the internal structure of the evaluated `Guardfile` or `.Guardfile`, with the `.guard.rb` file. You can
read more about these files in the [shared configuration section](https://github.com/guard/guard#shared-configurations).

Interactions
------------

Guard shows a [Pry](http://pryrepl.org/) console whenever it has nothing to do and comes with some Guard specific Pry
commands:

 * `↩`, `a`, `all`: Run all plugins.
 * `h`, `help`: Show help for all interactor commands.
 * `c`, `change`: Trigger a file change.
 * `n`, `notification`: Toggles the notifications.
 * `p`, `pause`: Toggles the file listener.
 * `r`, `reload`: Reload all plugins.
 * `o`, `scope`: Scope Guard actions to plugins or groups.
 * `s`, `show`: Show all Guard plugins.
 * `e`, `exit`: Stop all plugins and quit Guard

The `all` and `reload` commands supports an optional scope, so you limit the Guard action to either a Guard plugin or
a Guard group like:

```bash
[1]  guard(main)> all rspec
[2]  guard(main)> all frontend
```

Remember, you can always use `help` on the Pry command line to see all available commands and `help <command>` for
more detailed information. `help guard` will show all Guard related commands available

Pry supports the Ruby built-in Readline, [rb-readline](https://github.com/luislavena/rb-readline) and
[Coolline](https://github.com/Mon-Ouie/coolline). Just install the readline implementation of your choice by adding it
to your `Gemfile.

You can also disable the interactions completely by running Guard with the `--no-interactions` option.

### Customizations

Further Guard specific customizations can be made in `~/.guardrc` that will be evaluated prior the Pry session is
started (`~/.pryrc` is ignored). This allows you to make use of the Pry plugin architecture to provide custom commands
and extend Guard for your own needs and distribute as a gem. Please have a look at the
[Pry Wiki](https://github.com/pry/pry/wiki) for more information.

### Signals

You can also interact with Guard by sending POSIX signals to the Guard process (all but Windows and JRuby).

#### Pause watching

```bash
$ kill -USR1 <guard_pid>
```

#### Continue watching

```bash
$ kill -USR2 <guard_pid>
```

Guardfile DSL
-------------

The Guardfile DSL is evaluated as plain Ruby, so you can use normal Ruby code in your `Guardfile`.
Guard itself provides the following DSL methods that can be used for configuration:

### guard

The `guard` method allows you to add a Guard plugin to your toolchain and configure it by passing the
options after the name of the plugin:

```ruby
guard :coffeescript, :input => 'coffeescripts', :output => 'javascripts'
```

You can define the same plugin more than once:

```ruby
guard :coffeescript, :input => 'coffeescripts', :output => 'javascripts'
guard :coffeescript, :input => 'specs', :output => 'specs'
```

### watch

The `watch` method allows you to define which files are watched by a Guard:

```ruby
guard :bundler do
  watch('Gemfile')
end
```

String watch patterns are matched with [String#==](http://www.ruby-doc.org/core-1.9.2/String.html#method-i-3D-3D).
You can also pass a regular expression to the watch method:

```ruby
guard :jessie do
  watch(%r{^spec/.+(_spec|Spec)\.(js|coffee)})
end
```

This instructs the jessie plugin to watch for file changes in the `spec` folder,
but only for file names that ends with `_spec` or `Spec` and have a file type of `js` or `coffee`.

You can easily test your watcher regular expressions with [Rubular](http://rubular.com/).

When you add a block to the watch expression, you can modify the file name that has been
detected before sending it to the plugin for processing:

```ruby
guard :rspec do
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
end
```

In this example the regular expression capture group `(.+)` is used to transform a file change
in the `lib` folder to its test case in the `spec` folder. Regular expression watch patterns
are matched with [Regexp#match](http://www.ruby-doc.org/core-1.9.2/Regexp.html#method-i-match).

You can also launch any arbitrary command in the supplied block:

```ruby
guard :shell do
  watch('.*') { `git status` }
end
```

### group

The `group` method allows you to group several plugins together. This comes in handy especially when you
have a huge `Guardfile` and want to focus your development on a certain part.

```ruby
group :specs do
  guard :rspec do
    watch(%r{^spec/.+_spec\.rb$})
  end
end

group :docs do
  guard :ronn do
    watch(%r{^man/.+\.ronn?$})
  end
end
```

Groups to be run can be specified with the Guard DSL option `--group` (or `-g`):

```bash
$ guard -g specs
```

Guard plugins that don't belong to a group are considered global and are always run.

### scope

The `scope` method allows you to define the default plugin or group scope for Guard, if not
specified as command line option. Thus command line group and plugin scope takes precedence over
the DSL scope configuration.

You can define either a single plugin or group:

```ruby
scope :plugin => :rspec
scope :group => :docs
```

or specify multiple plugins or groups.

```ruby
scope :plugins => [:test, :jasmine]
scope :groups => [:docs, :frontend]
```

If you define both the plugin and group scope, the plugin scope has precedence. If you use both the
plural and the singular option, the plural has precedence.

### notification

If you don't specify any notification configuration in your `Guardfile`, Guard goes through the list of available
notifiers and takes the first that is available. If you specify your preferred library, auto detection will not take
place:

```ruby
notification :growl
```

will select the `growl` gem for notifications. You can also set options for a notifier:

```ruby
notification :growl, :sticky => true
```

Each notifier has a slightly different set of supported options:

```ruby
notification :growl, :sticky => true, :host => '192.168.1.5', :password => 'secret'
notification :gntp, :sticky => true, :host => '192.168.1.5', :password => 'secret'
notification :growl_notify, :sticky => true, :priority => 0
notification :libnotify, :timeout => 5, :transient => true, :append => false, :urgency => :critical
notification :notifu, :time => 5, :nosound => true, :xp => true
notification :emacs
```

It's possible to use more than one notifier. This allows you to configure different notifiers for different OS if your
project is developed cross-platform or if you like to have local and remote notifications.

Notifications can also be turned off in the `Guardfile`, in addition to setting the environment variable `GUARD_NOTIFY`
or using the cli switch `-n`:

```ruby
notification :off
```

### interactor

You can customize the Pry interactor history and RC file like:

```ruby
interactor :guard_rc => '~/.my_guard-rc', :history_file => '~/.my_guard_history_file'
```

If you do not need the Pry interactions with Guard at all, you can turn it off:

```ruby
interactor :off
```

### callback

The `callback` method allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`,
`run_all`, `run_on_changes`, `run_on_additions`, `run_on_modifications` and `run_on_removals` Guard plugins method.
You can even insert more hooks inside these methods.

```ruby
guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})

  callback(:start_begin) { `mate .` }
end
```

Please see the [hooks and callbacks](https://github.com/guard/guard/wiki/Hooks-and-callbacks) page in the Guard wiki for
more details.

### ignore

The `ignore` method can be used to exclude files and directories from the set of files being watched. Let's say you have
used the `watch` method to monitor a directory, but you are not interested in changes happening to images, you could use
the ignore method to exclude them.

This comes in handy when you have large amounts of non-source data in you project. By default
[`.rbx`, `.bundle`, `.git`, `.svn`, `log`, `tmp`, `vendor`](https://github.com/guard/listen/blob/master/lib/listen/directory_record.rb#L14)
are ignored.

Please note that method only accept regexps. More on the
[Listen README](https://github.com/guard/listen#the-patterns-for-filtering-and-ignoring-paths).

To append to the default ignored files and directories, use the `ignore` method:

```ruby
ignore %r{^ignored/path/}, /public/
```

To _replace_ to default ignored files and directories, use the `ignore!` method:

```ruby
ignore! /data/
```

### filter

The `filter` method allows you to focus by filtering files and directories without having to specify them by hand in the
`watch` method. E.g. if you are watching multiple directories but only interested in changes to the Ruby files, then use
the `filter` method.

Please note that method only accept regexps. More on the
[Listen README](https://github.com/guard/listen#the-patterns-for-filtering-and-ignoring-paths).

```ruby
filter /\.txt$/, /.*\.zip/
```

To _replace_ any existing filter, use the `filter!` method:

```ruby
filter /\.js$/
```

### logger

The `logger` method allows you to customize the [Lumberjack](https://github.com/bdurand/lumberjack) log output to your
needs by specifying one or more options like:

```ruby
logger :level       => :warn,
       :template    => '[:severity - :time - :progname] :message',
       :time_format => 'at %I:%M%p',
       :only        => [:rspec, :jasmine, 'coffeescript'],
       :except      => :jammit,
       :device      => 'guard.log'
```

Log `:level` option must be either `:debug`, `:info`, `:warn` or `:error`. If Guard is started in debug mode, the log
level will be automatically set to `:debug`.

The `:template` option is a string which can have one or more of the following placeholders: `:time`, `:severity`,
`:progname`, `:pid`, `:unit_of_work_id` and `:message`. A unit of work is assigned for each action Guard performs on
multiple Guard plugin.

The `:time_format` option directives are the same as Time#strftime or can be `:milliseconds`

The `:only` and `:except` are either a string or a symbol, or an array of strings or symbols that matches the name of
the Guard plugin name that sends the log message. They cannot be specified at the same time.

By default the logger uses `$stderr` as device, but you can override this by supplying the `:device` option and set
either an IO stream or a filename.

### Example

```ruby
ignore %r{^ignored/path/}, /public/
filter /\.txt$/, /.*\.zip/

notification :growl_notify
notification :gntp, :host => '192.168.1.5'

group :backend do
  guard :bundler do
    watch('Gemfile')
  end

  guard :rspec, :cli => '--color --format doc' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})         { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^spec/models/.+\.rb$})   { ["spec/models", "spec/acceptance"] }
    watch(%r{^spec/.+\.rb$})          { `say hello` }
    watch('spec/spec_helper.rb')      { "spec" }
  end
end

group :frontend do
  guard :coffeescript, :output => 'public/javascripts/compiled' do
    watch(%r{^app/coffeescripts/.+\.coffee$})
  end

  guard :livereload do
    watch(%r{^app/.+\.(erb|haml)$})
  end
end
```

Shared configurations
---------------------

You may optionally place a `.Guardfile` in your home directory to use it across multiple projects. It's evaluated when
you have no `Guardfile` in your current directory.

If a `.guard.rb` is found in your home directory, it will be appended to the `Guardfile` in your current directory.
This can be used for tasks you want guard to handle but other users probably don't.

For example, indexing your source tree with [Ctags](http://ctags.sourceforge.net):

```ruby
guard :shell do
  watch(%r{^(?:app|lib)/.+\.rb$}) { `ctags -R` }
end
```

File an issue
-------------

You can report bugs and feature requests to [GitHub Issues](https://github.com/guard/guard/issues).

**Please don't ask question in the issue tracker**, instead ask them in our
[Google group](http://groups.google.com/group/guard-dev) or on `#guard` (irc.freenode.net).

Try to figure out where the issue belongs to: Is it an issue with Guard itself or with a Guard plugin you're
using?

When you file a bug, please try to follow these simple rules if applicable:

* Make sure you've read the README carefully.
* Make sure you run Guard with `bundle exec` first.
* Add debug information to the issue by running Guard with the `--debug` option.
* Add your `Guardfile` and `Gemfile` to the issue.
* Provide information about your environment:
  * Your current versions of your OS, Ruby, Rubygems and Bundler.
  * Shared project folder with services like Dropbox, NFS, etc.
* Make sure that the issue is reproducible with your description.

**It's most likely that your bug gets resolved faster if you provide as much information as possible!**

Development
-----------

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested. All specs run with `rake spec:portability` must pass.
* Update the [Yard](http://yardoc.org/) documentation.
* Update the [README](https://github.com/guard/guard/blob/master/README.md).
* Update the [CHANGELOG](https://github.com/guard/guard/blob/master/CHANGELOG.md) for noteworthy changes.
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))

### Core Team

* [Maher Sallam](https://github.com/Maher4Ever) ([@mahersalam](http://twitter.com/mahersalam))
* [Michael Kessler](https://github.com/netzpirat) ([@netzpirat](http://twitter.com/netzpirat), [mksoft.ch](https://mksoft.ch))
* [Rémy Coutable](https://github.com/rymai) ([@rymai](http://twitter.com/rymai), [rymai.me](http://rymai.me))
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg), [thibaud.me](http://thibaud.me/))

### Contributors

[https://github.com/guard/guard/contributors](https://github.com/guard/guard/contributors)
