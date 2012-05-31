Guard [![Build Status](https://secure.travis-ci.org/guard/guard.png?branch=master)](http://travis-ci.org/guard/guard)
=====

Guard is a command line tool to easily handle events on file system modifications.

This document contains a lot of information, please take your time and read these instructions carefully. If you have
any questions, ask them in our [Google group](http://groups.google.com/group/guard-dev) or on `#guard`
(irc.freenode.net).

Before you file an issue, make sure you have read the _[file an issue](#file-an-issue)_ section that contains some
important information.

Features
--------

* File system changes handled by our awesome [Listen](https://github.com/guard/listen) gem.
* Support for visual system notifications.
* Huge ([more than 120](https://rubygems.org/search?query=guard-)) guard extensions eco-system.
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

If you are using Windows and want colors in your terminal, you'll have to add the
[win32console](https://rubygems.org/gems/win32console) gem to your `Gemfile` and install it with Bundler:

```ruby
group :development do
  gem 'win32console'
end
```

**It's important that you always run Guard through Bundler to avoid errors.** If you're getting sick of typing `bundle exec` all
the time, try the [Rubygems Bundler](https://github.com/mpapis/rubygems-bundler).

### System notifications

You can configure Guard to make use of the following system notification libraries, but it's strongly recommended
to use either Ruby GNTP, Libnotify or Notifu:

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

#### Ruby GNTP

**There's currently a bug in Growl that prevents displaying the icons through GNTP, see
[issue #231](https://github.com/guard/guard/issues/231). Use the growl gem until fixed.**

* Runs on Mac OS X, Linux and Windows
* Supports [Growl](http://growl.info/) version >= 1.3, [Growl for Linux](http://mattn.github.com/growl-for-linux/),
  [Growl for Windows](http://www.growlforwindows.com/gfw/default.aspx) and
  [Snarl](https://sites.google.com/site/snarlapp/home)

The [ruby_gntp](https://rubygems.org/gems/ruby_gntp) gem sends system notifications over the network with the
[Growl Notification Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx) and supports local and
remote notifications.

Guard supports multiple notification channels for customizing each notification type. For Growl on Mac OS X you need
to have at least version 1.3 installed.

To use `ruby_gntp` you have to add it to your `Gemfile` and run bundler:

```ruby
group :development do
  gem 'ruby_gntp'
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

Add more Guards
---------------

Guard is now ready to use and you should add some Guards for your specific use. Start exploring the many Guards
available by browsing the [Guard organization](https://github.com/guard) on GitHub or by searching for `guard-` on
[RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=guard-).

When you have found a Guard of your interest, add it to your `Gemfile`:

```ruby
group :development do
  gem '<guard-name>'
end
```

See the init section of the Guard usage below to see how to install the supplied Guard template that you can install and
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

You can generate a Guardfile and have all installed guards be automatically added into
it by running the `init` task without any option:

```bash
$ guard init
```

You can also specify the name of an installed Guard to only get that Guard
in the generated Guardfile:

```bash
$ guard init <guard-name>
```

You can also define your own templates in `~/.guard/templates/` which can be appended in the same way to your existing
`Guardfile`:

```bash
$ guard init <template-name>
```

**Note**: If you already have a `Guardfile` in the current directory, the `init` task can be used
to append a supplied Guard template from an installed Guard to your existing
`Guardfile`.

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

#### `-n`/`--notify` option

System notifications can be disabled:

```bash
$ guard --notify false
$ guard -n f # shortcut
```

Notifications can also be disabled globally by setting a `GUARD_NOTIFY` environment variable to `false`.

#### `-g`/`--group` option

Only certain Guard groups can be run:

```bash
$ guard --group group_name another_group_name
$ guard -g group_name another_group_name # shortcut
```

See the Guardfile DSL below for creating groups.

#### `-d`/`--debug` option

Guard can display debug information which can be very usefull for plugins
developers with:

```bash
$ guard --debug
$ guard -d # shortcut
```

#### `-w`/`--watchdir` option

Guard can watch in any directory instead of the current directory:

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

You can list the available Guards with the `list` task:

```bash
$ guard list

Available guards:
   coffeescript
   compass
   cucumber
   jammit
   ronn
   rspec *
   spork
   yard
See also https://github.com/guard/guard/wiki/List-of-available-Guards
* denotes ones already in your Guardfile
```

### Show

You can show the structure of the groups and their Guards with the `show` task:

```bash
$ guard show

(global):
  shell
Group backend:
  bundler
  rspec: cli => "--color --format doc"
Group frontend:
  coffeescript: output => "public/javascripts/compiled"
  livereload
```

This shows the internal structure of the evaluated `Guardfile` or `.Guardfile`, with the `.guard.rb` file. You can
read more about these files in the shared configuration section below.

Interactions
------------

You can interact with Guard and enter commands when Guard has nothing to do. Guard understands the following commands:

* `↩`:                 Run all Guards.
* `h`, `help`:         Show a help of the available interactor commands.
* `r`, `reload`:       Reload all Guards.
* `n`, `notification`: Toggle system notifications on and off.
* `p`, `pause`:        Toggles the file modification listener. The prompt will change to `p>` when paused.
                       This is useful when switching Git branches, rebase Git or change whitespace.
* `e`, `exit`:         Stop all Guards and quit Guard.

Instead of running all Guards with the `↩` key, you can also run a single Guard by entering its name:

```bash
> rspec
```

It's also possible to run all Guards within a group by entering the group name:

```bash
> frontend
```

The same applies to Guard reloading. You can reload a Guard with the following command:

```bash
> ronn reload
```

This will reload only the Ronn Guard. You can also reload all Guards within a group:

```bash
> backend reload
```

### Readline support

With Readline enabled, you'll see a command prompt `>` when Guard is ready to accept a command. The command line
supports history navigation with the `↑` and `↓` arrow keys, and command auto-completion with the `⇥` key.

Unfortunately Readline [does not work on MRI](http://bugs.ruby-lang.org/issues/5539) on Mac OS X by default. You can
work around the issue by installing a pure Ruby implementation:

```ruby
platforms :ruby do
  gem 'rb-readline'
end
```

Guard will automatically enable Readline support if your environment supports it, but you can disable Readline with the
`interactor` DSL method or turn off completely with the `--no-interactions` option.

### Signals

You can also interact with Guard by sending POSIX signals to the Guard process (all but Windows).

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

The `guard` method allows you to add a Guard to your toolchain and configure it by passing the
options after the name of the Guard:

```ruby
guard :coffeescript, :input => 'coffeescripts', :output => 'javascripts'
```

You can define the same Guard more than once:

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

This instructs the jessie Guard to watch for file changes in the `spec` folder,
but only for file names that ends with `_spec` or `Spec` and have a file type of `js` or `coffee`.

You can easily test your watcher regular expressions with [Rubular](http://rubular.com/).

When you add a block to the watch expression, you can modify the file name that has been
detected before sending it to the Guard for processing:

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

The `group` method allows you to group several Guards together. This comes in handy especially when you
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

Guards that don't belong to a group are considered global and are always run.

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
```

It's possible to use more than one notifier. This allows you to configure different notifiers for different OS if your
project is developed cross-platform or if you like to have local and remote notifications.

Notifications can also be turned off in the `Guardfile`, in addition to setting the environment variable `GUARD_NOTIFY`
or using the cli switch `-n`:

```ruby
notification :off
```

### interactor

You can disable the interactor auto detection and for a specific implementation:

```ruby
interactor :readline
```

will select Readline interactor. You can also force the simple interactor without Readline support with:

```ruby
interactor :simple
```

If you do not need the keyboard interactions with Guard at all, you can turn them off:

```ruby
interactor :off
```

### callback

The `callback` method allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`,
`run_all` and `run_on_change` Guards' method. You can even insert more hooks inside these methods.

```ruby
guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})

  callback(:start_begin) { `mate .` }
end
```

Please see the [hooks and callbacks](https://github.com/guard/guard/wiki/Hooks-and-callbacks) page in the Guard wiki for
more details.

### ignore

The `ignore` method allows you to ignore specific paths. This comes is handy when you have large
amounts of non-source data in you project. By default [`.rbx`, `.bundle`, `.git`, `.svn`, `log`, `tmp`, `vendor`](https://github.com/guard/listen/blob/master/lib/listen/directory_record.rb#L14) are ignored.
Please note that method only accept regexps. More on the [Listen README](https://github.com/guard/listen#the-patterns-for-filtering-and-ignoring-paths).

```ruby
ignore %r{^ignored/path/}, /public/
```

### filter

The `filter` method allows you to filter specific paths.
Please note that method only accept regexps. More on the [Listen README](https://github.com/guard/listen#the-patterns-for-filtering-and-ignoring-paths).

```ruby
filter /\.txt$/, /.*\.zip/
```

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

Try to figure out where the issue belongs to: Is it an issue with Guard itself or with a Guard implementation you're
using?

When you file a bug, please try to follow these simple rules if applicable:

* Make sure you run Guard with `bundle exec` first.
* Add debug information to the issue by running Guard with the `--debug` option.
* Add your `Guardfile` and `Gemfile` to the issue.
* Make sure that the issue is reproducible with your description.

**It's most likely that your bug gets resolved faster if you provide as much information as possible!**

Development [![Dependency Status](https://gemnasium.com/guard/guard.png?branch=master)](https://gemnasium.com/guard/guard)
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
