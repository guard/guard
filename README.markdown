Guard
=====

Guard is a command line tool that easily handle events on files modifications.

Features
--------

* [FSEvent](http://en.wikipedia.org/wiki/FSEvents) support on Mac OS X 10.5+ (without RubyCocoa!, [rb-fsevent gem, >= 0.3.5](https://rubygems.org/gems/rb-fsevent) required).
* [Inotify](http://en.wikipedia.org/wiki/Inotify) support on Linux ([rb-inotify gem, >= 0.5.1](https://rubygems.org/gems/rb-inotify) required).
* Polling on the other operating systems (help us to support more OS).
* Automatic & Super fast (when polling is not used) files modifications detection (even new files are detected).
* Growl notifications ([growlnotify](http://growl.info/documentation/growlnotify.php) & [growl gem](https://rubygems.org/gems/growl) required).
* Libnotify notifications ([libnotify gem](https://rubygems.org/gems/libnotify) required).
* Tested on Ruby 1.8.6, 1.8.7 & 1.9.2.

Install
-------

Install the gem:

    $ gem install guard

Add it to your Gemfile (inside the <tt>test</tt> group):

``` ruby
gem 'guard'
```

Generate an empty Guardfile with:

    $ guard init

Add the guards you need to your Guardfile (see the existing guards below).

### On Mac OS X

Install the rb-fsevent gem for [FSEvent](http://en.wikipedia.org/wiki/FSEvents) support:

    $ gem install rb-fsevent

Install the Growl gem if you want notification support:

    $ gem install growl

And add it to you Gemfile:

``` ruby
gem 'growl'
```

### On Linux

Install the rb-inotify gem for [inotify](http://en.wikipedia.org/wiki/Inotify) support:

    $ gem install rb-inotify

Install the Libnotify gem if you want notification support:

    $ gem install libnotify

And add it to you Gemfile:

``` ruby
gem 'libnotify'
```

Usage
-----

Just launch Guard inside your Ruby / Rails project with:

    $ guard [start]

or if you use Bundler, to run the Guard executable specific to your bundle:

    $ bundle exec guard

Command line options
--------------------

Shell can be cleared after each change with:

    $ guard --clear
    $ guard -c # shortcut

Notifications (growl/libnotify) can be disabled with:

    $ guard --notify false
    $ guard -n false # shortcut

The guards to start can be specified by group (see the Guardfile DSL below) specifying the <tt>--group</tt> (or <tt>-g</tt>) option:

    $ guard --group group_name another_group_name
    $ guard -g group_name another_group_name # shortcut

Options list is available with:

    $ guard help [TASK]

Signal handlers
---------------

Signal handlers are used to interact with Guard:

* <tt>Ctrl-C</tt> - Calls each guard's <tt>stop</tt> method, in the same order they are declared in the Guardfile, and then quits Guard itself.
* <tt>Ctrl-\\</tt> - Calls each guard's <tt>run_all</tt> method, in the same order they are declared in the Guardfile.
* <tt>Ctrl-Z</tt> - Calls each guard's <tt>reload</tt> method, in the same order they are declared in the Guardfile.

Available Guards
----------------

[Available Guards list](https://github.com/guard/guard/wiki/List-of-available-Guards) (on the wiki now)

### Add a guard to your Guardfile

Add it to your Gemfile (inside the <tt>test</tt> group):

``` ruby
gem '<guard-name>'
```

Insert default guard's definition to your Guardfile by running this command:

    $ guard init <guard-name>

You are good to go!

Guardfile DSL
-------------

The Guardfile DSL consists of just three simple methods: <tt>guard</tt>, <tt>watch</tt> & <tt>group</tt>.

Required:
* The <tt>guard</tt> method allows you to add a guard with an optional hash of options.
* The <tt>watch</tt> method allows you to define which files are supervised by this guard. An optional block can be added to overwrite the paths sent to the <tt>run_on_change</tt> guard method or to launch any arbitrary command.

Optional:
* The <tt>group</tt> method allows you to group several guards together. Groups to be run can be specified with the Guard DSL option <tt>--group</tt> (or <tt>-g</tt>). This comes in handy especially when you have a huge Guardfile and want to focus your development on a certain part.

Example:

``` ruby
group 'backend' do
  guard 'bundler' do
    watch('Gemfile')
  end

  guard 'rspec', :cli => '--color --format doc' do
    # Regexp watch patterns are matched with Regexp#match
    watch(%r{^spec/.+_spec\.rb})
    watch(%r{^lib/(.+)\.rb})         { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^spec/models/.+\.rb})   { ["spec/models", "spec/acceptance"] }
    watch(%r{^spec/.+\.rb})          { `say hello` }

    # String watch patterns are matched with simple '=='
    watch('spec/spec_helper.rb') { "spec" }
  end
end

group 'frontend' do
  guard 'coffeescript', :output => 'public/javascripts/compiled' do
    watch(%r{^app/coffeescripts/.+\.coffee})
  end

  guard 'livereload' do
    watch(%r{^app/.+\.(erb|haml)})
  end
end
```

Create a new guard
------------------

Creating a new guard is very easy, just create a new gem (<tt>bundle gem</tt> if you use Bundler) with this basic structure:

    lib/
      guard/
        guard-name/
          templates/
            Guardfile (needed for guard init <guard-name>)
        guard-name.rb

<tt>Guard::GuardName</tt> (in <tt>lib/guard/guard-name.rb</tt>) must inherit from <tt>Guard::Guard</tt> and should overwrite at least one of the five basic <tt>Guard::Guard</tt> instance methods. Example:

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

    # Called on Ctrl-/ signal
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

Please take a look at the existing guards' source code (see the list above) for more concrete example.

Alternatively, a new guard can be added inline to a Guardfile with this basic structure:

``` ruby
require 'guard/guard'

module ::Guard
  class Example < ::Guard::Guard
    def run_all
      true
    end

    def run_on_change(paths)
      true
    end
  end
end
```

Development
-----------

* Source hosted at [GitHub](https://github.com/guard/guard).
* Report Issues/Questions/Feature requests on [GitHub Issues](https://github.com/guard/guard/issues).

Pull requests are very welcome! Make sure your patches are well tested. Please create a topic branch for every separate change
you make.

Author
------

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg)
