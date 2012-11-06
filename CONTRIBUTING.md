Contribute to Guard
===================

File an issue
-------------

You can report bugs and feature requests to [GitHub Issues](https://github.com/guard/guard/issues).

**Please don't ask question in the issue tracker**, instead ask them on at Stack Overflow and use the
[guard](http://stackoverflow.com/questions/tagged/guard) tag.

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
