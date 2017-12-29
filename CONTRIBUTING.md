Contribute to Guard
===================

File an issue
-------------

Please check guard's [GitHub issue tracker](https://github.com/guard/guard/issues) for known issues.  Additionally you should check [listen's issue tracker](https://github.com/guard/listen/issues) for issues which affect guard's behaviour; for example, there is currently a nasty [bug preventing listen from watching files inside symlinked directories](https://github.com/guard/listen/issues/25).

You can report bugs and feature requests to [GitHub Issues](https://github.com/guard/guard/issues).

**Please don't ask question in the issue tracker**, instead ask them at one of our other places:

* Use the guard tag at [StackOverflow](http://stackoverflow.com/questions/tagged/guard).
* [Google+ community](https://plus.google.com/u/1/communities/110022199336250745477)
* [Google group](http://groups.google.com/group/guard-dev)
* IRC channel `#guard` (irc.freenode.net) for chatting

Try to figure out where the issue belongs to: is it an issue with Guard itself or with a Guard plugin you're using (e.g. guard-rspec, guard-cucumber, etc.)?

When you file a bug, please try to follow these simple rules if applicable:

* Make sure you've read the README carefully.
* Make sure you run Guard with `bundle exec` first.
* Add debug information to the issue by running Guard with the `--debug` option
* Add your `Guardfile` and `Gemfile` to the issue.
* Provide information about your environment:
  * Your current versions of your OS, Ruby, Rubygems and Bundler.
  * Shared project folder with services like Dropbox, NFS, etc.
* Make sure that the issue is reproducible with your description.
* If Guard is not responding to file changes and/or is not firing rules correctly:
  * see [listen](http://github.com/guard/listen) for more info on troubleshooting.
  * run guard with the `LISTEN_GEM_DEBUGGING` environment variable set to 1 (info) or 2 (debug) which shows what's happening under the hood and how fast)
* If you are using plugins, check out their respective README files (disabling spring, adding bundle to plugin's command, special debug options, etc.)

**It's most likely that your bug gets resolved faster if you provide as much information as possible!**

Development
-----------

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard).
* The [wiki](https://github.com/guard/guard/wiki/) has useful developer documentation, including:
  * [how to create a guard plugin](https://github.com/guard/guard/wiki/Create-a-guard), and
  * [understanding Guard](https://github.com/guard/guard/wiki/Understanding-Guard),
    which contains useful debugging tips.

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* TIP: run `rubocop` locally before pushing (so your PR won't trigger HoundCI comments)
* Make sure your patches are well tested. All specs must pass when run on [Travis CI](https://travis-ci.org/guard/guard).
* Update the [Yard](http://yardoc.org/) documentation.
* Update the [README](https://github.com/guard/guard/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).
