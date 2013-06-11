Guard [![Gem Version](https://badge.fury.io/rb/guard.png)](http://badge.fury.io/rb/guard) [![Build Status](https://travis-ci.org/guard/guard.png?branch=master)](https://travis-ci.org/guard/guard) [![Dependency Status](https://gemnasium.com/guard/guard.png)](https://gemnasium.com/guard/guard) [![Code Climate](https://codeclimate.com/github/guard/guard.png)](https://codeclimate.com/github/guard/guard) [![Coverage Status](https://coveralls.io/repos/guard/guard/badge.png?branch=master)](https://coveralls.io/r/guard/guard)
=====

<img src="http://img515.imageshack.us/img515/1358/guardicon.png" alt="Guard Icon" align="right" />
Guard is a command line tool to easily handle events on file system modifications.

This document contains a lot of information, please take your time and read these instructions carefully. If you have
any questions about the Guard usage or want to share some information with the Guard community, please go to one of
the following places:

* [Google+ community](https://plus.google.com/u/1/communities/110022199336250745477)
* [Google group](http://groups.google.com/group/guard-dev)
* [StackOverflow](http://stackoverflow.com/questions/tagged/guard)
* IRC channel `#guard` (irc.freenode.net) for chatting

Information on advanced topics like creating your own Guard plugin, programatic use of Guard, hooks and callbacks and
more can be found in the [Guard wiki](https://github.com/guard/guard/wiki).

Before you file an issue, make sure you have read the _[known issues](#known-issues)_ and _[file an issue](#file-an-issue)_ sections that contains some important information.

#### Features

* File system changes handled by our awesome [Listen](https://github.com/guard/listen) gem.
* Support for visual system notifications.
* Huge eco-system with [more than 190](https://rubygems.org/search?query=guard-) guard plugins.
* Tested against Ruby 1.8.7, 1.9.2, 1.9.3, 2.0.0, REE and the latest versions of JRuby & Rubinius.

#### Screencast

Two nice introduction screen casts to Guard are available that helps you get started:

* [Guard is Your Best Friend](http://net.tutsplus.com/tutorials/tools-and-tips/guard-is-your-best-friend) on Net Tuts+
* [Guard](http://railscasts.com/episodes/264-guard) on RailsCast

Installation
------------

The simplest way to install Guard is to use [Bundler](http://gembundler.com/).

Add Guard (and any other dependencies) to a `Gemfile` in your project’s root:

```ruby
group :development do
  gem 'guard'
end
```

then install it by running Bundler:

```bash
$ bundle
```

Generate an empty `Guardfile` with:

```bash
$ guard init
```

Run Guard through Bundler with:

```bash
$ bundle exec guard
```

**It's important that you always run Guard through Bundler to avoid errors.** If you're getting sick of typing
`bundle exec` all the time, try the [Rubygems Bundler](https://github.com/mpapis/rubygems-bundler).

If you are on Mac OS X and have problems with either Guard not reacting to file changes or Pry behaving strange, then
you should [add proper Readline support to Ruby on Mac OS X](https://github.com/guard/guard/wiki/Add-Readline-support-to-Ruby-on-Mac-OS-X).

#### Add Guard plugins

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
| Group   | Plugin | Option          | Value                      |
+---------+--------+-----------------+----------------------------+
| Specs   | Rspec  | all_after_pass  | true                       |
|         |        | all_on_start    | true                       |
|         |        | cli             | "--fail-fast --format doc" |
|         |        | focus_on_failed | false                      |
|         |        | keep_failed     | true                       |
|         |        | run_all         | {}                         |
|         |        | spec_paths      | ["spec"]                   |
+---------+--------+-----------------+----------------------------+
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

If the Pry interactor is used, then `Ctrl-C` is delegated to Pry to exit continuation and `Ctrl-D` to exit Guard.
Without interactor, `Ctrl-C` exits Guard and `Ctrl-D` is ignored.

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

Another neat use of groups is to group dependant plugins and stop processing if one fails. In order
to make this work, the group needs to have the `halt_on_fail` option enabled and the Guard plugin
needs to throw `:task_has_failed` to indicate that the action was not successful.

```ruby
group :specs, :halt_on_fail => true do
  guard :rspec do
    watch(/.../)
  end

  guard :cucumber do
    watch(/.../)
  end
end
```

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
notifiers and enables all that are available. If you specify your preferred library, auto detection will not take
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
filter! /\.js$/
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

Issues
------

Please check guard's [GitHub issue tracker](https://github.com/guard/guard/issues) for known issues.  Additionally you should check [listen's issue tracker](https://github.com/guard/listen/issues) for issues which affect guard's behaviour; for example, there is currently a nasty [bug preventing listen from watching files inside symlinked directories](https://github.com/guard/listen/issues/25).

#### File an issue

You can report bugs and feature requests to [GitHub Issues](https://github.com/guard/guard/issues).

**Please don't ask question in the issue tracker**, instead ask them at one of our other places:

* [Google+ community](https://plus.google.com/u/1/communities/110022199336250745477)
* [Google group](http://groups.google.com/group/guard-dev)
* [StackOverflow](http://stackoverflow.com/questions/tagged/guard)
* IRC channel `#guard` (irc.freenode.net) for chatting

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
* Make sure your patches are well tested. All specs must pass on [Travis CI](https://travis-ci.org/guard/guard).
* Update the [Yard](http://yardoc.org/) documentation.
* Update the [README](https://github.com/guard/guard/blob/master/README.md).
* Update the [CHANGELOG](https://github.com/guard/guard/blob/master/CHANGELOG.md) for noteworthy changes (don't forget to run `bundle exec pimpmychangelog` and watch the magic happen)!
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

#### Open Commit Bit

Guard has an open commit bit policy: Anyone with an accepted pull request gets added as a repository collaborator.
Please try to follow these simple rules:

* Commit directly onto the master branch only for typos, improvements to the readme and documentation (please add
  `[ci skip]` to the commit message).
* Create a feature branch and open a pull-request early for any new features to get feedback.
* Make sure you adhere to the general pull request rules above.

#### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))

#### Core Team

* [Maher Sallam](https://github.com/Maher4Ever) ([@mahersalam](http://twitter.com/mahersalam))
* [Michael Kessler](https://github.com/netzpirat) ([@netzpirat](http://twitter.com/netzpirat), [mksoft.ch](https://mksoft.ch))
* [Rémy Coutable](https://github.com/rymai) ([@rymai](http://twitter.com/rymai), [rymai.me](http://rymai.me))
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg), [thibaud.me](http://thibaud.me/))

#### Contributors

[https://github.com/guard/guard/contributors](https://github.com/guard/guard/contributors)
