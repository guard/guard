Guard [![Build Status](https://secure.travis-ci.org/guard/guard.png)](http://travis-ci.org/guard/guard)
=====

Guard is a command line tool that easily handle events on files modifications.

If you have any questions please join us on our [Google group](http://groups.google.com/group/guard-dev) or on `#guard` (irc.freenode.net).

Features
--------

* [FSEvent](http://en.wikipedia.org/wiki/FSEvents) support on Mac OS X 10.5+ (without RubyCocoa!, [rb-fsevent gem, >= 0.3.5](https://rubygems.org/gems/rb-fsevent) required).
* [Inotify](http://en.wikipedia.org/wiki/Inotify) support on Linux ([rb-inotify gem, >= 0.5.1](https://rubygems.org/gems/rb-inotify) required).
* [Directory Change Notification](http://msdn.microsoft.com/en-us/library/aa365261\(VS.85\).aspx) support on Windows ([rb-fchange, >= 0.0.2](https://rubygems.org/gems/rb-fchange) required).
* Polling on the other operating systems (help us to support more OS).
* Automatic & Super fast (when polling is not used) files modifications detection (even new files are detected).
* Visual notifications on Mac OSX ([Growl](http://growl.info)), Linux ([Libnotify](http://developer.gnome.org/libnotify)) and Windows ([Notifu](http://www.paralint.com/projects/notifu)).
* Tested against Ruby 1.8.7, 1.9.2, REE and the latest versions of JRuby & Rubinius.

Screencast
----------

Ryan Bates made a Railscast on Guard, you can view it here: http://railscasts.com/episodes/264-guard

Install
-------

Install the gem:

``` bash
$ gem install guard
```

Or add it to your Gemfile (inside the `development` group):

``` ruby
gem 'guard'
```

and install it via Bundler:

``` bash
$ bundle install
```

Generate an empty Guardfile with:

``` bash
$ guard init
```

You may optionally place a .Guardfile in your home directory to use it across multiple projects.
Also note that if a `.guard.rb` is found in your home directory, it will be appended to the Guardfile.

Add the guards you need to your Guardfile (see the existing guards below).

### On Mac OS X

Install the rb-fsevent gem for [FSEvent](http://en.wikipedia.org/wiki/FSEvents) support:

``` bash
$ gem install rb-fsevent
```

You have two possibilities:

Use the [growl_notify gem](https://rubygems.org/gems/growl_notify) (recommended):

``` bash
$ gem install growl_notify
```

Use the [growlnotify](http://growl.info/extras.php#growlnotify) (cli tool for growl) + the [growl gem](https://rubygems.org/gems/growl).

``` bash
$ brew install growlnotify
$ gem install growl
```

And add them to your Gemfile:

``` ruby
gem 'rb-fsevent'
gem 'growl_notify' # or gem 'growl'
```

The difference between growl and growl_notify is that growl_notify uses AppleScript to
display a message, whereas growl uses the `growlnotify` command. In general the AppleScript
approach is preferred, but you may also use the older growl gem. Have a look at the
[Guard Wiki](https://github.com/guard/guard/wiki/Use-growl_notify-or-growl-gem) for more information.

### On Linux

Install the [rb-inotify gem](https://rubygems.org/gems/rb-inotify) for [inotify](http://en.wikipedia.org/wiki/Inotify) support:

``` bash
$ gem install rb-inotify
```

Install the [libnotify gem](https://rubygems.org/gems/libnotify) if you want visual notification support:

``` bash
$ gem install libnotify
```

And add them to your Gemfile:

``` ruby
gem 'rb-inotify'
gem 'libnotify'
```

### On Windows

Install the [rb-fchange gem](https://rubygems.org/gems/rb-fchange) for [Directory Change Notification](http://msdn.microsoft.com/en-us/library/aa365261\(VS.85\).aspx) support:

``` bash
$ gem install rb-fchange
```

Install the [win32console gem](https://rubygems.org/gems/win32console) if you want colors in your terminal:

``` bash
$ gem install win32console
```

Install the [rb-notifu gem](https://rubygems.org/gems/rb-notifu) if you want visual notification support:

``` bash
$ gem install rb-notifu
```

And add them to your Gemfile:

``` ruby
gem 'rb-fchange'
gem 'rb-notifu'
gem 'win32console'
```

Usage
-----

Just launch Guard inside your Ruby / Rails project with:

``` bash
$ guard [start]
```

or if you use Bundler, to run the Guard executable specific to your bundle:

``` bash
$ bundle exec guard [start]
```

Guard will look for a Guardfile in your current directory. If it does not find one, it will look in your `$HOME` directory for a .Guardfile.

Command line options
--------------------

### `-c`/`--clear` option

Shell can be cleared after each change:

``` bash
$ guard --clear
$ guard -c # shortcut
```

### `-n`/`--notify` option

Notifications (growl/libnotify) can be disabled:

``` bash
$ guard --notify false
$ guard -n f # shortcut
```

Notifications can also be disabled globally by setting a `GUARD_NOTIFY` environment variable to `false`

### `-g`/`--group` option

Only certain guards groups can be run (see the Guardfile DSL below for creating groups):

``` bash
$ guard --group group_name another_group_name
$ guard -g group_name another_group_name # shortcut
```

### `-d`/`--debug` option

Guard can be run in debug mode:

``` bash
$ guard --debug
$ guard -d # shortcut
```

### `-w`/`--watchdir` option

Guard can watch in any directory (instead of the current directory):

``` bash
$ guard --watchdir ~/your/fancy/project
$ guard -w ~/your/fancy/project # shortcut
```

### `-G`/`--guardfile` option

Guard can use a Guardfile not located in the current directory:

``` bash
$ guard --guardfile ~/.your_global_guardfile
$ guard -G ~/.your_global_guardfile # shortcut
```

An exhaustive list of options is available with:

``` bash
$ guard help [TASK]
```

Interactions
------------

**From version >= 0.7.0 Posix Signal handlers are no more used to interact with Guard. If you're using a version < 0.7, please refer to the [README in the v0.6 branch](https://github.com/guard/guard/blob/v0.6/README.md).**

When Guard do nothing you can interact with by entering a command + hitting enter:

* `stop|quit|exit|s|q|e + enter` - Calls each guard's `#stop` method, in the same order they are declared in the Guardfile, and then quits Guard itself.
* `reload|r|z + enter` - Calls each guard's `#reload` method, in the same order they are declared in the Guardfile.
* `pause|p + enter` - Toggle files modification listening. Useful when switching git branches.
* `just enter (no commands)` - Calls each guard's `#run_all` method, in the same order they are declared in the Guardfile.

Available Guards
----------------

A list of the available guards is present [in the wiki](https://github.com/guard/guard/wiki/List-of-available-Guards).

### Add a guard to your Guardfile

Add it to your Gemfile (inside the `development` group):

``` ruby
gem '<guard-name>'
```

You can list all guards installed on your system with:

``` bash
$ guard list
```

Insert default guard's definition to your Guardfile by running this command:

``` bash
$ guard init <guard-name>
```

You are good to go, or you can modify your guards' definition to suit your needs.

Guardfile DSL
-------------

The Guardfile DSL consists of the following methods:

* `#guard`: allows you to add a guard with an optional hash of options.
* `#watch`: allows you to define which files are supervised by this guard. An optional block can be added to overwrite the paths sent to the guard's `#run_on_change` method or to launch any arbitrary command.
* `#group`: allows you to group several guards together. Groups to be run can be specified with the Guard DSL option `--group` (or `-g`). This comes in handy especially when you have a huge Guardfile and want to focus your development on a certain part. Guards that don't belong to a group are considered global and are always run.
* `#callback`: allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`, `run_all` and `run_on_change` guards' method. You can even insert more hooks inside these methods. Please [checkout the Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for more details.
* `#ignore_paths`: allows you to ignore top level directories altogether.  This comes is handy when you have large amounts of non-source data in you project.  By default .bundle, .git, log, tmp, and vendor are ignored.  Currently it is only possible to ignore the immediate descendants of the watched directory.

Example:

``` ruby
ignore_paths 'foo', 'bar'

group 'backend' do
  guard 'bundler' do
    watch('Gemfile')
  end

  guard 'rspec', :cli => '--color --format doc' do
    # Regexp watch patterns are matched with Regexp#match
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})         { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^spec/models/.+\.rb$})   { ["spec/models", "spec/acceptance"] }
    watch(%r{^spec/.+\.rb$})          { `say hello` }

    # String watch patterns are matched with simple '=='
    watch('spec/spec_helper.rb') { "spec" }
  end
end

group 'frontend' do
  guard 'coffeescript', :output => 'public/javascripts/compiled' do
    watch(%r{^app/coffeescripts/.+\.coffee$})
  end

  guard 'livereload' do
    watch(%r{^app/.+\.(erb|haml)$})
  end
end
```

Using a Guardfile without the `guard` binary
--------------------------------------------

The Guardfile DSL can also be used in a programmatic fashion by calling directly `Guard::Dsl.evaluate_guardfile`.
Available options are as follow:

* `:guardfile`          - The path to a valid Guardfile.
* `:guardfile_contents` - A string representing the content of a valid Guardfile

Remember, without any options given, Guard will look for a Guardfile in your current directory and if it does not find one, it will look for it in your `$HOME` directory.

For instance, you could use it as follow:

``` ruby
gem 'guard'
require 'guard'

Guard.setup

Guard::Dsl.evaluate_guardfile(:guardfile => '/your/custom/path/to/a/valid/Guardfile')
# or
Guard::Dsl.evaluate_guardfile(:guardfile_contents => "
  guard 'rspec' do
    watch(%r{^spec/.+_spec\.rb$})
  end
")
```

### Listing defined guards/groups for the current project

You can list the defined groups and guards for the current Guardfile from the command line using `guard show` or `guard -T`:

``` bash
# guard -T

(global):
  shell
Group backend:
  bundler
  rspec: cli => "--color --format doc"
Group frontend:
  coffeescript: output => "public/javascripts/compiled"
  livereload
```

User config file
----------------

If a `.guard.rb` is found in your home directory, it will be appended to
the Guardfile.  This can be used for tasks you want guard to handle but
other users probably don't.  For example, indexing your source tree with
[Ctags](http://ctags.sourceforge.net):

``` ruby
guard 'shell' do
  watch(%r{^(?:app|lib)/.+\.rb$}) { `ctags -R` }
end
```

Create a new guard
------------------

Creating a new guard is very easy, just create a new gem (`bundle gem` if you use Bundler) with this basic structure:

```
.travis.yml  # bonus point!
CHANGELOG.md # bonus point!
Gemfile
guard-name.gemspec
Guardfile
lib/
  guard/
    guard-name/
      templates/
        Guardfile # needed for `guard init <guard-name>`
      version.rb
    guard-name.rb
test/ # or spec/
README.md
```

`Guard::GuardName` (in `lib/guard/guard-name.rb`) must inherit from `Guard::Guard` and should overwrite at least one of the five basic `Guard::Guard` instance methods.

Here is an example scaffold for `lib/guard/guard-name.rb`:

``` ruby
require 'guard'
require 'guard/guard'

module Guard
  class GuardName < Guard

    def initialize(watchers=[], options={})
      super
      # init stuff here, thx!
    end

    # =================
    # = Guard methods =
    # =================

    # If one of those methods raise an exception, the Guard::GuardName instance
    # will be removed from the active guards.

    # Called once when Guard starts
    # Please override initialize method to init stuff
    def start
      true
    end

    # Called on Ctrl-C signal (when Guard quits)
    def stop
      true
    end

    # Called on Ctrl-Z signal
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    def reload
      true
    end

    # Called on Ctrl-\ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
      true
    end

    # Called on file(s) modifications
    def run_on_change(paths)
      true
    end

  end
end
```

Please take a look at the [existing guards' source code](https://github.com/guard/guard/wiki/List-of-available-Guards) for more concrete example and inspiration.

Alternatively, a new guard can be added inline to a Guardfile with this basic structure:

``` ruby
require 'guard/guard'

module ::Guard
  class InlineGuard < ::Guard::Guard
    def run_all
      true
    end

    def run_on_change(paths)
      true
    end
  end
end
```

Here is a very cool example by [@avdi](https://github.com/avdi) : http://avdi.org/devblog/2011/06/15/a-guardfile-for-redis

Development
-----------

* Source hosted at [GitHub](https://github.com/guard/guard).
* Report issues and feature requests to [GitHub Issues](https://github.com/guard/guard/issues).

Pull requests are very welcome! Please try to follow these simple "rules", though:

- Please create a topic branch for every separate change you make;
- Make sure your patches are well tested;
- Update the README (if applicable);
- Update the CHANGELOG (maybe not for a typo but don't hesitate!);
- Please **do not change** the version number.

For questions please join us on our [Google group](http://groups.google.com/group/guard-dev) or on `#guard` (irc.freenode.net).

Author
------

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg)

Contributors
------------

https://github.com/guard/guard/contributors
