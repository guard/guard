Guard [![Build Status](https://secure.travis-ci.org/guard/guard.png?branch=master)](http://travis-ci.org/guard/guard)
=====

Guard is a command line tool to easily handle events on file system modifications.

If you have any questions please join us on our [Google group](http://groups.google.com/group/guard-dev) or on `#guard` (irc.freenode.net).

Features
--------

* [FSEvent](http://en.wikipedia.org/wiki/FSEvents) support on Mac OS X.
* [Inotify](http://en.wikipedia.org/wiki/Inotify) support on Linux.
* [Directory Change Notification](http://msdn.microsoft.com/en-us/library/aa365261\(VS.85\).aspx) support on Windows.
* Polling on the other operating systems (help us to support more OS).
* Automatic and super fast (when polling is not used) file modification detection (even new and deleted files are detected).
* Support for visual system notifications.
* Tested against Ruby 1.8.7, 1.9.2, REE and the latest versions of JRuby & Rubinius.

Screencast
----------

Ryan Bates made a RailsCast on Guard, you can view it here: [http://railscasts.com/episodes/264-guard](http://railscasts.com/episodes/264-guard)

Install
-------

Add Guard to your `Gemfile`:

    group :development do
      gem 'guard'
      gem 'rb-inotify', :require => false   # Linux
      gem 'rb-fsevent', :require => false   # Mac OS X
      gem 'rb-fchange', :require => false   # Windows
    end

and install it by executing [Bundler](http://gembundler.com/):

    $ bundle

Generate an empty `Guardfile` with:

    $ guard init

Guard is now ready to use, but you should add some Guards for your specific use. Start exploring the many Guards
available by browsing the [Guard organization](https://github.com/guard) on GitHub or by searching for `guard-` on
[RubyGems](https://rubygems.org/search?utf8=%E2%9C%93&query=guard-).

If you are using Windows and want colors in your terminal, you'll have to add the
[win32console](https://rubygems.org/gems/win32console) gem to your `Gemfile` and install it with Bundler:

    group :development
      gem 'win32console'
    end

### Shared configurations

You may optionally place a `.Guardfile` in your home directory to use it across multiple projects. It's evaluated when
you have no `Guardfile` in your current directory.

If a `.guard.rb` is found in your home directory, it will be appended to the `Guardfile` in your current directory.

### System notifications

You can configure Guard to make use of the following system notification libraries:

#### Ruby GNTP

* Runs on Mac OS X, Linux, Windows
* Supports [Growl](http://growl.info/), [Growl for Linux](http://mattn.github.com/growl-for-linux/), [Growl for Windows](http://www.growlforwindows.com/gfw/default.aspx) and [Snarl](https://sites.google.com/site/snarlapp/home)

The [ruby_gntp](https://rubygems.org/gems/ruby_gntp) gem sends system notifications over the network with the
[Growl Notification Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx) and supports local and
remote notifications.

Guard supports multiple notification channels for customizing each notification type. For Growl on Mac OS X you need
to have at least version 1.3 installed.

To use `ruby_gntp` you have to add it to your `Gemfile` and run bundler:

    group :development
      gem 'ruby_gntp'
    end

#### GrowlNotify

* Runs on Mac OS X
* Supports [Growl](http://growl.info/)

The [growl_notify](https://rubygems.org/gems/growl_notify) gem uses AppleScript to send Growl notifications.
The gem needs a native C extension to make use of AppleScript and does not run on JRuby and MacRuby.

Guard supports multiple notification channels for customizing each notification type and you need to have at least
Growl version 1.3 installed.

To use `growl_notify` you have to add it to your `Gemfile` and run bundler:

    group :development
      gem 'growl_notify'
    end

#### Growl

* Runs on Mac OS X
* Supports [Growl](http://growl.info/)

The [growl](https://rubygems.org/gems/growl) gem is compatible with all versions of Growl and uses a command line tool
[growlnotify](http://growl.info/extras.php#growlnotify) that must be separately downloaded and installed. The version of
the command line tool must match your Growl version. The `growl` gem does **not** support multiple notification channels.

You can download an installer for `growlnotify` from the [Growl download section](http://growl.info/downloads) or
install it with HomeBrew:

    $ brew install growlnotify

To use `growl` you have to add it to your `Gemfile` and run bundler:

    group :development
      gem 'growl'
    end

#### Libnotify

* Runs on Linux, FreeBSD, OpenBSD and Solaris
* Supports [Libnotify](http://developer.gnome.org/libnotify/)

The [libnotify](https://rubygems.org/gems/libnotify) gem supports the Gnome libnotify notification daemon, but it can be
used on other window managers as well. You have to install the `libnotify-bin` package with your favorite package manager.

To use `libnotify` you have to add it to your `Gemfile` and run bundler:

    group :development
      gem 'libnotify'
    end

#### Notifu

* Runs on Windows
* Supports [Notifu](http://www.paralint.com/projects/notifu/)

The [rb-notifu](https://rubygems.org/gems/rb-notifu) gem supports Windows system tray notifications.

To use `rb-notifu` you have to add it to your `Gemfile` and run bundler:

    group :development
      gem 'rb-notifu'
    end

Usage
-----

Just launch Guard inside your Ruby / Rails project with:

    $ bundle exec guard

Guard will look for a Guardfile in your current directory. If it does not find one, it will look in your `$HOME` directory for a .Guardfile.

Command line options
--------------------

### `-c`/`--clear` option

Shell can be cleared after each change:

    $ guard --clear
    $ guard -c # shortcut

### `-n`/`--notify` option

System notifications can be disabled:

    $ guard --notify false
    $ guard -n f # shortcut

Notifications can also be disabled globally by setting a `GUARD_NOTIFY` environment variable to `false`.

### `-g`/`--group` option

Only certain guards groups can be run (see the Guardfile DSL below for creating groups):

    $ guard --group group_name another_group_name
    $ guard -g group_name another_group_name # shortcut

### `-d`/`--debug` option

Guard can be run in debug mode:

    $ guard --debug
    $ guard -d # shortcut

### `-w`/`--watchdir` option

Guard can watch in any directory (instead of the current directory):

    $ guard --watchdir ~/your/fancy/project
    $ guard -w ~/your/fancy/project # shortcut

### `-G`/`--guardfile` option

Guard can use a Guardfile not located in the current directory:

    $ guard --guardfile ~/.your_global_guardfile
    $ guard -G ~/.your_global_guardfile # shortcut

### `-A`/`--watch-all-modifications` option

Guard can optionally watch all file modifications like moves or deletions with:

    $ guard start -A
    $ guard start --watch-all-modifications

### `-i`/`--no-interactions` option

Turn off completely any Guard terminal [interactions](#interactions) with:

    $ guard start -A
    $ guard start --watch-all-modifications

An exhaustive list of options is available with:

    $ guard help [TASK]

<a name="interactions" />

Interactions
------------

**From version >= 0.7.0 Posix Signal handlers are no more used to interact with Guard. If you're using a version < 0.7, please refer to the [README in the v0.6 branch](https://github.com/guard/guard/blob/v0.6/README.md).**

When Guard do nothing you can interact with by entering a command + hitting return/enter:

* `stop`:    `stop|quit|exit|s|q|e + return` - Calls each guard's `#stop` method, in the same order they are declared in the Guardfile, and then quits Guard itself.
* `reload`:  `reload|r|z + return` - Calls each guard's `#reload` method, in the same order they are declared in the Guardfile.
* `pause`:   `pause|p + return` - Toggle files modification listening. Useful when switching git branches.
* `run_all`: `just return (no commands)` - Calls each guard's `#run_all` method, in the same order they are declared in the Guardfile.

`reload` and `run_all` actions can be scoped to only run on a certain guard or group. Examples:

* `backend reload + return` - Call only each guard's `#reload` method on backend group.
* `rspec + return` - Call only rspec guard's `#run_all` method.

Adding more Guards
------------------

### Add a guard to your Guardfile

Add it to your `Gemfile`:

    group :development
      gem '<guard-name>'
    end

You can list all Guards installed on your system with:

    $ guard list

Insert the supplied Guard template to your `Guardfile` by running this command:

    $ guard init <guard-name>

You are good to go, or you can modify your Guards' definition to suit your needs.

Guardfile DSL
-------------

The Guardfile DSL consists of the following methods:

* `#guard`        - Allows you to add a guard with an optional hash of options.
* `#watch`        - Allows you to define which files are supervised by a guard. An optional block can be added to overwrite the paths sent to the guard's `#run_on_change` method or to launch any arbitrary command.
* `#group`        - Allows you to group several guards together. Groups to be run can be specified with the Guard DSL option `--group` (or `-g`). This comes in handy especially when you have a huge Guardfile and want to focus your development on a certain part. Guards that don't belong to a group are considered global and are always run.
* `#notification` - Allows you to choose and configure your preferred system notification library.
* `#callback`     - Allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`, `run_all` and `run_on_change` guards' method. You can even insert more hooks inside these methods. Please [checkout the Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for more details.
* `#ignore_paths` - Allows you to ignore top level directories altogether. This comes is handy when you have large amounts of non-source data in you project.  By default .bundle, .git, log, tmp, and vendor are ignored.  Currently it is only possible to ignore the immediate descendants of the watched directory.

Example:

    notification :gntp
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

### Configure system notifications

If you don't specify any notification configuration in your Guardfile, Guard goes through the list of available
notifiers and takes the first that is available. If you specify your preferred library, auto detection will not take place:

    notification :growl

will select the `growl` gem for notifications. You can also set options for a notifier:

    notification :growl, :sticky => true

Each notifier has a slightly different set of supported options:

    notification :growl, :sticky => true, :host => '192.168.1.5', :password => 'secret'
    notification :gntp, :sticky => true, :host => '192.168.1.5', :password => 'secret'
    notification :growl_notify, :sticky => true, :priority => 0
    notification :libnotify, :timeout => 5, :transient => true, :append => false
    notification :notifu, :time => 5, :nosound => true, :xp => true

It's possible to use more than one notifier. This allows you to configure different notifiers for different OS if your
project is developed cross-platform or if you like to have local and remote notifications.

Notifications can also be turned off in the Guardfile, in addition to setting the environment variable `GUARD_NOTIFY`
or using the cli switch `-n`:

    notification :off

Using a Guardfile without the `guard` binary
--------------------------------------------

The Guardfile DSL can also be used in a programmatic fashion by calling directly `Guard::Dsl.evaluate_guardfile`.
Available options are as follow:

* `:guardfile`          - The path to a valid Guardfile.
* `:guardfile_contents` - A string representing the content of a valid Guardfile

Remember, without any options given, Guard will look for a Guardfile in your current directory and if it does not find one, it will look for it in your `$HOME` directory.

For instance, you could use it as follow:

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

### Listing defined guards/groups for the current project

You can list the defined groups and guards for the current Guardfile from the command line using `guard show` or `guard -T`:

    $ guard -T

    (global):
      shell
    Group backend:
      bundler
      rspec: cli => "--color --format doc"
    Group frontend:
      coffeescript: output => "public/javascripts/compiled"
      livereload

User config file
----------------

If a `.guard.rb` is found in your home directory, it will be appended to
the Guardfile.  This can be used for tasks you want guard to handle but
other users probably don't.  For example, indexing your source tree with
[Ctags](http://ctags.sourceforge.net):

    guard 'shell' do
      watch(%r{^(?:app|lib)/.+\.rb$}) { `ctags -R` }
    end

Create a new guard
------------------

Creating a new guard is very easy, just create a new gem (`bundle gem` if you use Bundler) with this basic structure:

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

`Guard::GuardName` (in `lib/guard/guard-name.rb`) must inherit from
[Guard::Guard](http://rubydoc.info/github/guard/guard/master/Guard/Guard) and should overwrite at least one of
the basic `Guard::Guard` task methods.

Here is an example scaffold for `lib/guard/guard-name.rb`:

    require 'guard'
    require 'guard/guard'

    module Guard
      class GuardName < Guard

        # Initialize a Guard.
        # @param [Array<Guard::Watcher>] watchers the Guard file watchers
        # @param [Hash] options the custom Guard options
        def initialize(watchers = [], options = {})
          super
        end

        # Call once when Guard starts. Please override initialize method to init stuff.
        # @raise [:task_has_failed] when start has failed
        def start
        end

        # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
        # @raise [:task_has_failed] when stop has failed
        def stop
        end

        # Called when `reload|r|z + enter` is pressed.
        # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
        # @raise [:task_has_failed] when reload has failed
        def reload
        end

        # Called when just `enter` is pressed
        # This method should be principally used for long action like running all specs/tests/...
        # @raise [:task_has_failed] when run_all has failed
        def run_all
        end

        # Called on file(s) modifications that the Guard watches.
        # @param [Array<String>] paths the changes files or paths
        # @raise [:task_has_failed] when run_on_change has failed
        def run_on_change(paths)
        end

        # Called on file(s) deletions that the Guard watches.
        # @param [Array<String>] paths the deleted files or paths
        # @raise [:task_has_failed] when run_on_change has failed
        def run_on_deletion(paths)
        end

      end
    end

Please take a look at the [existing guards' source code](https://github.com/guard/guard/wiki/List-of-available-Guards)
for more concrete example and inspiration.

Alternatively, a new guard can be added inline to a Guardfile with this basic structure:

    require 'guard/guard'

    module ::Guard
      class InlineGuard < ::Guard::Guard
        def run_all
        end

        def run_on_change(paths)
        end
      end
    end

Here is a very cool example by [@avdi](https://github.com/avdi) : [http://avdi.org/devblog/2011/06/15/a-guardfile-for-redis](http://avdi.org/devblog/2011/06/15/a-guardfile-for-redis)

Development
-----------

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard/master/frames).
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

[https://github.com/guard/guard/contributors](https://github.com/guard/guard/contributors)
