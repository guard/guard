### :warning: Guard is [looking for new maintainers](https://groups.google.com/forum/#!topic/guard-dev/2Td0QTvTIsE). Please [contact me](mailto:thibaud@thibaud.gg) if you're interested.

Guard
=====

[![Gem Version](https://img.shields.io/gem/v/guard.svg?style=flat)](https://rubygems.org/gems/guard) [![Build Status](https://travis-ci.org/guard/guard.svg)](https://travis-ci.org/guard/guard) [![Dependency Status](https://gemnasium.com/guard/guard.png)](https://gemnasium.com/guard/guard) [![Code Climate](https://codeclimate.com/github/guard/guard/badges/gpa.svg)](https://codeclimate.com/github/guard/guard) [![Test Coverage](https://codeclimate.com/github/guard/guard/badges/coverage.svg)](https://codeclimate.com/github/guard/guard) [![Inline docs](http://inch-ci.org/github/guard/guard.svg)](http://inch-ci.org/github/guard/guard)

<img src="http://cl.ly/image/1k3o1r2Z3a0J/guard-Icon.png" alt="Guard Icon" align="right" />
Guard is a command line tool to easily handle events on file system modifications.

Guard has many very handy features, so read this document through at least once
to be aware of them - or you'll likely miss out on really cool ideas and tricks.

Also, by reading through you'll likely avoid common and time-consuming problems which Guard simply can't automatically solve.

If you have
any questions about the Guard usage or want to share some information with the Guard community, please go to one of
the following places:

* [Google+ community](https://plus.google.com/u/1/communities/110022199336250745477).
* [Google group](http://groups.google.com/group/guard-dev).
* [StackOverflow](http://stackoverflow.com/questions/tagged/guard).
* IRC channel `#guard` (irc.freenode.net) for chatting.

Information on advanced topics like creating your own Guard plugin, programmatic use of Guard, hooks and callbacks and
more can be found in the [Guard wiki](https://github.com/guard/guard/wiki).

Before you file an issue, make sure you have read the _[known issues](#issues)_ and _[file an issue](#file-an-issue)_ sections that contains some important information.

#### Features

* File system changes handled by our awesome [Listen](https://github.com/guard/listen) gem.
* Support for visual system notifications.
* Huge eco-system with [more than 220](https://rubygems.org/search?query=guard-) Guard plugins.
* Tested against Ruby 1.9.3, 2.0.0, 2.1.0, JRuby & Rubinius.

#### Screencast

Two nice screencasts are available to help you get started:

* [Guard](http://railscasts.com/episodes/264-guard) on RailsCast.
* [Guard is Your Best Friend](http://net.tutsplus.com/tutorials/tools-and-tips/guard-is-your-best-friend) on Net Tuts+.

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
$ bundle exec guard init
```

Run Guard through Bundler with:

```bash
$ bundle exec guard
```

If you are on Mac OS X and have problems with either Guard not reacting to file
changes or Pry behaving strange, then you should [add proper Readline support
to Ruby on Mac OS
X](https://github.com/guard/guard/wiki/Add-Readline-support-to-Ruby-on-Mac-OS-X).


#### Avoiding gem/dependency problems

**It's important that you always run Guard through Bundler to avoid errors.**

If you're getting sick of typing `bundle exec` all the time, try one of the following:

* (Recommended) Running `bundle binstub guard` will create `bin/guard` in your
  project, which means running `bin/guard` (tab completion will save you a key
  stroke or two) will have the exact same result as `bundle exec guard`.

* Or, for RubyGems >= 2.2.0 (at least, though the more recent the better),
  simply set the `RUBYGEMS_GEMDEPS` environment variable to `-` (for autodetecting
  the Gemfile in the current or parent directories) or set it to the path of your Gemfile.

(To upgrade RubyGems from RVM, use the `rvm rubygems` command).

*NOTE: this Rubygems feature is still under development still lacks many features of bundler*

* Or, for RubyGems < 2.2.0 check out the [Rubygems Bundler](https://github.com/mpapis/rubygems-bundler).

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

Look here for a full [list of Guard commands](https://github.com/guard/guard/wiki/List-of-Guard-Commands)

### Start

Just launch Guard inside your Ruby or Rails project with:

```bash
$ bundle exec guard
```

Guard will look for a `Guardfile` in your current directory. If it does not find one, it will look in your `$HOME`
directory for a `.Guardfile`.

Please look here to see all the [command line options for Guard](https://github.com/guard/guard/wiki/Command-line-options-for-Guard)

Interactions
------------
Please read how to [interact with Guard](https://github.com/guard/guard/wiki/Interacting-with-Guard) on the console and which [signals](https://github.com/guard/guard/wiki/Interacting-with-Guard#guard-signals) Guard accepts


Guardfile DSL
-------------
For details on extending your `Guardfile` look at [Guardfile examples](https://github.com/guard/guard/wiki/Guardfile-examples) or look at a list of commands [Guardfile-DSL / Configuring-Guard](https://github.com/guard/guard/wiki/Guardfile-DSL---Configuring-Guard)

Issues
------

Before reporting a problem, please read how to [File an issue](https://github.com/guard/guard/blob/master/CONTRIBUTING.md#file-an-issue).

Development / Contributing
--------------------------

See the [Contributing Guide](https://github.com/guard/guard/blob/master/CONTRIBUTING.md#development).


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

* R.I.P. :broken_heart: [Michael Kessler](https://github.com/netzpirat) ([@netzpirat](http://twitter.com/netzpirat), [flinkfinger.com](http://www.flinkfinger.com)).
* [Rémy Coutable](https://github.com/rymai).
* [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg), [thibaud.gg](http://thibaud.gg/)).

#### Contributors

[https://github.com/guard/guard/graphs/contributors](https://github.com/guard/guard/graphs/contributors)
