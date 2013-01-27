## 1.6.2 - 27 January, 2013

### Improvements

- Allow the logger device to be set with the `:device` option. ([@netzpirat][])
- Improve `list` and `show` command output. ([@netzpirat][])
- [#386][] Replace Pry's reset command. ([@envygeeks][])

### Bug fixes

- [#389][] Fix `list` and `show` commands. ([@netzpirat][])
- [#387][] Load the users defined guardrc file. ([@envygeeks][])

## 1.6.1 - 27 December, 2012

### Improvements

- [#344][] Restore Pry visibility after each evaluation. (reported by [@rking][], fixed by [@netzpirat][])

## 1.6.0 - 21 December, 2012

### New features

- Allow the Guard scope to be defined from the `Guardfile` with the `scope` DSL method. ([@netzpirat][])
- [#378][] Scope plugins and groups from CLI and interactor. ([@netzpirat][])
- [#369][] Allow Guard plugins to specify their template location. ([@schmurfy][])
- [#364][] Add `ignore!` and `filter!` DSL methods. ([@tarsolya][])
- [#362][] Add interactor options `:history_file` and `:guard_rc`. ([@netzpirat][])

### Improvements

- [#372][] Restore original TMux settings on stop. ([@rudicode][])
- [#376][] Delegate Ctrl-C to Pry to exit continuation. ([@netzpirat][])
- [#360][] Improve Guard/listen/interactor thread coordination. ([@netzpirat][])
- [#368][] Detecting duplicate definitions and then warning the user. ([@jfolkins][])
- [#367][] Change modeline's fgcolor when changing bgcolor in emacs notifier. ([@iljoo][])

### Bug fixes

- [#377][] Add the 'a' alias for the 'all' Pry command. (reported by [@cknadler][], fixed by [@rymai][])
- [#365][] Fix terminal reset redirect to null devise on Windows. ([@cablegram][])
- [#365][] Fix Emacs notifier detection on Windows. ([@cablegram][])
- [#361][] Tmux notifier affects only the local session. ([@netzpirat][])

## 1.5.4 - 9 November, 2012

### Improvements

- Thread handling improved and added thread debug mode. ([@netzpirat][])

### Bug fix

- [#358][] Ignore `~/.pryrc` since it breaks Guard when loading the Rails env. ([@netzpirat][])

## 1.5.3 - 31 October, 2012

### Bug fixes

- [#352][] Guard always reloading twice. ([@netzpirat][])
- [#354][] Ignore `./.pryrc` since it breaks Guard when loading the Rails env. ([@netzpirat][])

## 1.5.2 - 29 October, 2012

### Bug fix

- [#353][] Do not modify original message in terminal_title notifier. ([@tomas-zemres][])

## 1.5.1 - 28 October, 2012

### Bug fix

- [#351][] Fix turning off the interactor from the Guardfile. ([@netzpirat][])

## 1.5.0 - 22 October, 2012

### New features

- [#327][] Use Pry as interactor. ([@netzpirat][])
- [#345][] Use Lumberjack as customizable logger. ([@netzpirat][])
- [#342][] Add notifier for displaying result in terminal title. ([@tomas-zemres][])
- [#348][] Introduce grouping of the notifiers for better auto-detection. ([@netzpirat][])

### Improvements

- [#348][] Introduce grouping of the notifiers. ([@netzpirat][])
- [#343][] Customize tmux notifier status location. ([@nickmabry][])
- Adds ability to override default options in emacs notifier. ([@d1][])
- Use `$stderr` instead of `STDERR` to allow redirection. ([@netzpirat][])
- [#334][] Extend `:tmux` notifier with use of `tmux display-message` and options to configure them. ([@matthijsgroen][])

## 1.4.0 - 26 September, 2012

- [#331][] Add tmux notifier. ([@royvandewater][])

## 1.3.3 - 20 September, 2012

- Add Guard application icon to GNTP notifier. ([@netzpirat][])
- [#324][] Allow Terminal Notifier title to be customizable. ([@mattgreen][])

## 1.3.2 - 15 August, 2012

### Improvements

- [#316][] Guard clears screen more than once per single watch event. (reported by [@japgolly][], fixed by [@thibaudgg][])

## 1.3.1 - 14 August, 2012

### Improvements

- [#317][] Switch to Terminal-Notifier-Guard gem. ([@foxycoder][])
- [#315][] Improve Emacs detection. ([@maio][])

## 1.3.0 - 3 August, 2012

### Bug fix

- [#299][] Fix Readline interactor on JRruby. ([@netzpirat][])

### Improvements

- Add support for OS X notification center ([@foxycoder][])
- Add support for Emacs notifications ([@maio][])
- Add support for multiple guards being passed to `guard init`. ([@jredville][])

### 1.2.1 - 2 July, 2012

### Bug fix

- Fix template methods in the Guard plugin class that causes loss of listen changes. ([@netzpirat][])

### 1.2.2 - 2 July, 2012

### Bug fix

- [#298][] Deprecations must be explicit enabled. ([@netzpirat][])

### 1.2.1 - 20 June, 2012

### Bug fix

- Work around a Listen issue where the stop task isn't executed. ([@netzpirat][])

### 1.2.0 - 20 June, 2012

### Improvements

- Add a [Coolline](https://github.com/Mon-Ouie/coolline) based interactor (Ruby 1.9.3 only). ([@netzpirat][])
- More flexible command parser for all interactors. ([@netzpirat][])
- Add 'show' command to describe all plugins in the interactor. ([@netzpirat][])
- Add 'change' command to trigger a file change event in the interactor. ([@netzpirat][])

## 1.1.1 - 3 June, 2012

### Bug fix

- [#283][] Fix `guard init`. (reported by [@ashleyconnor][], fixed by [@rymai][])

## 1.1.0 - 2 June, 2012

### Improvements

- Listening is now handled by the [Listen gem](https://github.com/guard/listen).
- Replace the `--verbose` option with the `--debug` option.
- New `--latency`/`-l` option to overwrite Listen's default latency.
- New `--force-polling`/`-p` option to force usage of the Listen polling listener.
- `--watch-all-modifications`/`-A` option is removed and is now always on.
- `--no-vendor`/`-I` option is removed because the monitoring gems are now part of the [Listen gem](https://github.com/guard/listen). You can specify a custom version of any monitoring gem directly in your Gemfile if you want to overwrite Listen's default monitoring gems.
- Guard plugins must now implement `run_on_additions`, `run_on_modifications`, `run_on_removals` and / or `run_on_changes`. The `run_on_change` and `run_on_deletion` methods are deprecated and should be removed as soon as possible. See the [Upgrade guide for existing guards to Guard v1.1](https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1) for more info.

The Listen integration has been supervised by [@thibaudgg][] and executed by [@Maher4Ever][], [@rymai][] and [@thibaudgg][].

## 1.0.3 - 14 May, 2012

### Improvement

- Improve Thor dependency '~> 0.14.6' => '>= 0.14.6'. ([@thibaudgg][])

## 1.0.2 - 30 April, 2012

### Improvements

- [#274][] and [#275][] Make the Bundler warning less scary and more friendly. ([@mcmire][])
- [#270][] Make urgency configurable for libnotify/notifysend. ([@viking][])
- [#254][] Add the possibility to pause/unpause by sending OS signal. ([@steakknife][])
- [#261][] Clarify the usage of the term `guard-name` in the README. ([@spadin][])
- Add a `--no-bundler-warning` option to Guard start. ([@netzpirat][])
- Update vendor/darwin. ([@thibaudgg][])

### Bug fixes

- [#260][] Don't show Bundler warning when no Gemfile present. ([@netzpirat][])
- [#259][] Fix `guard show` on Ruby 1.8.7. ([@netzpirat][] and [@rymai][])

## 1.0.1 - 7 March, 2012

### Improvements

- [#236][] Add support for `notifysend`. ([@alandipert][])
- Update vendor/darwin to rb-fsevent 0.9.0. ([@thibaudgg][])

### Bug fixes

- [#249][] and [#250][] Fix programmatic examples that didn't work. ([@oreoshake][])
- [#238][] Don't try to load the FSEvents listener on older versions of OSX. ([@philomory][])
- [#233][] `Guard::Listener.select_and_init` requires a hash. (reported by [@sunaku][], fixed by [@thibaudgg][])
- [#227][] and [#232][] Add the ability to initialize all guards at once. (proposed by [@rupert654][], done by [@Maher4Ever][])

## 1.0.0 - 19 January, 2012

### Improvements

- Add Gemnasium dependency status image to README. ([@laserlemon][])
- Update vendor/darwin. ([@thibaudgg][])
- [#223][] Warn if Guard isn't launched with `bundle exec`. (proposed by [@thibaudgg][], done by [@netzpirat][])

### Bug fixes

- [#226][] Use a direct file descriptor with stty. ([@netzpirat][])
- [#218][] Watching directory with `-A` option only reports a deleted file the first time around. ([@rymai][])
- [#174][] Not creating timestamps for new files with `-A` option. ([@rymai][])
- [#216][] Fix exit-status codes for Guard. ([@Maher4Ever][])
- [#213][] and [#214][] Fix the "ERROR: No guards found in Guardfile" message wrongly displayed when running `guard list`. ([@pirukire][])

## 0.10.0 - 1 January, 2012

### Improvements

- Improve Readline constraints. ([@netzpirat][])
- Stop and start all guards on Guardfile reevaluation. ([@thibaudgg][])

### Bug fix

- Terminal keep-alive causing ERROR: Unknown command. ([@waldo][])

## 0.9.4 - December 25, 2011

### Improvement

- Add the ability to load user defined templates. ([@hawx][])

### Bug fix

- Fix guard-rspec notifications by using ENV variable to store Notifier.notifications. ([@thibaudgg][])

## 0.9.3 - December 23, 2011

### Improvement

- Fix terminal status after interrupting the Readline interactor. ([@Maher4Ever][])

## 0.9.2 - December 22, 2011

### Improvements

- Add `interactor` to DSL to allow switching Guard interaction implementation. ([@netzpirat][])
- Add quit action to the interactor. ([@Maher4Ever][])

## 0.9.1 - December 19, 2011

### Bug fixes

- Fix wrong `--no-vendor` option. ([@netzpirat][])
- [#195][] Empty watch directory prohibit Guard from running. (reported by [@madtrick][], fixed by [@netzpirat][])

## 0.9.0 - December 19, 2011

### Bug fixes

- [#173][] Cannot set the watch_all_modifications option. (reported by [@sutherland][], fixed by [@netzpirat][])
- Fix `guard init` when a guard name is given. ([@rymai][])

### Improvements

- [#165][] Allow underscores in Guard name. ([@benolee][])
- Add readline support to the interactor. ([@netzpirat][])
- Add support for notification configuration. ([@netzpirat][])

## 0.8.8 - October 21, 2011

### Bug fix

- Fix `guard init` when a guard name is given. ([@rymai][])

## 0.8.7 - October 18, 2011

### Bug fix

- [#166][] Fix silent failure after re-evaluating Guardfile. (reported by [@dgutov][], fixed by [@rymai][], special thanks to [@dyfrgi][] for the [reproducible test case](https://github.com/dyfrgi/Guard-Broken))

## 0.8.6 - October 17, 2011

### Bug fixes

- [#168][] Fix `guard init` path to Guardfile template. (reported by [@semperos][])
- [#167][] Include objects in changed_paths when Guard allows any return from the watchers. (reported by [@earlonrails][], fixed by [@netzpirat][])

## 0.8.5 - October 17, 2011

### Improvements

- `reload` and `run_all` Guard terminal interactions actions can be scoped to only run on a certain guard or group. ([@thibaudgg][])
- Add cli option (`-i` / `--no-interactions`) to turn off Guard terminal interactions. ([@thibaudgg][])
- Add support for Growl Notification Transport Protocol. ([@netzpirat][])
- [#157][] Allow any return from the Guard watchers. ([@earlonrails][])
- [#156][] Log error and diagnostic messages to STDERR. ([@sunaku][])
- [#152][] Growl Notify API update for a graceful fail. ([@scottdavis][])

### Bug fix

- [#160][] Avoid `Guard is not missing constant ...` exceptions. (reported by [@earlonrails][], fixed by [@netzpirat][])

## 0.8.4 - October 3, 2011

### Bug fix

- [#149][] and [#150][] Fix issue where interactor thread was continuing to capture input from `stdin` while a guard is being executed. (reported by [@hardipe][], fixed by [@f1sherman][])

## 0.8.3 - October 1, 2011

### Bug fix

- [#145][] Fix over-utilization of CPU in Interactor. ([@johnbintz][])

### Improvements

- [#146][] Use a mutex instead of a lock for more efficient/simple locking. ([@f1sherman][])
- Make Guard implementation of `:task_has_failed` simple. ([@netzpirat][])

## 0.8.2 - September 30, 2011

### Bug fix

- Fix guard stop to prevent `run_guard_task(:stop)` from being skipped [guard-spork issue 28](https://github.com/guard/guard-spork/issues/28). ([@thibaudgg][])

### Improvement

- Update docs regarding `:task_has_failed`. ([@netzpirat][])

## 0.8.1 - September 29, 2011

### Bug fix

- [#144][] Fix `guard init`. (reported by [@fabioyamate][], fixed by [@rymai][])

## 0.8.0 - September 28, 2011

### Bug fixes

- [#137][] Fix interacting with tools like ruby-debug. ([@hron][] and [@netzpirat][])
- [#138][] Fix comments in example scaffold to reference interactions. ([@rmm5t][] and [@netzpirat][])

### New feature

- [#136][] New CLI `:watch_all_modifications`/`-A` option to watch for deleted and moved files too. ([@limeyd][] and [@netzpirat][])
- [#97][] Guard dependencies. Task execution can now be halted if a Guard throws `:task_has_failed` and `Guard::Dsl#group` options include `:halt_on_fail => true`. ([@rymai][])
- [#121][] `Guard.guards` and `Guard.groups` are now smart accessors. Filters can be passed to find a specific Guard/group or several Guard plugins/groups that match (see YARDoc). ([@rymai][] and [@ches][])
- New `Guard::Group` class to store groups defined in Guardfile (with `Guard::Dsl#group`). ([@rymai][])

### Improvements

- Specs refactoring. ([@netzpirat][])
- Full YARD documentation. ([@netzpirat][] and a little of [@rymai][])

## 0.7.0 - September 14, 2011

## 0.7.0.rc1 - September 5, 2011

### Major Changes

- Posix Signals handlers (`Ctrl-C`, `Ctrl-\` and `Ctrl-Z`) are no more supported and replaced by `$stdin.gets`. Please refer to the "Interactions" section in the README for more information. ([@thibaudgg][])
- JRuby and Rubinius support (beta). ([@thibaudgg][] and [@netzpirat][])

### New features

- [#42][] New DSL method: `callback` allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`, `run_all` and `run_on_change` guards' method. New [Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for documenting it. ([@monocle][] and [@rymai][])
- Ability to 'pause' files modification listening. Please refer to the "Interactions" section in the README for more information. ([@thibaudgg][])

### Improvement

- Remove the need to scan the whole directory after guard's `run_on_change` method. ([@thibaudgg][])

## 0.6.3 - September 1, 2011

### New features

- [#130][] Add `ignore_paths` method to DSL. ([@ianwhite][])
- [#128][] Users can add additional settings to `~/.guard.rb` that augment the existing Guardfile. ([@tpope][])

## 0.6.2 - August 17, 2011

### Bug fixes

- Re-add the possibility to use the `growl` gem since the `growl_notify` gem this is currently known to not work in conjunction with Spork. ([@netzpirat][])
- Ensure that scoped groups and group name are symbolized before checking for inclusion. ([@rymai][])

### New features

- Groups are now stored in a `groups` instance variable (will be used for future features). ([@rymai][])
- Guard plugins will now receive their group in the options hash at initialization (will be used for future features). ([@rymai][])

### Improvement

- Explain the growl/growl_notify differences in the README. ([@netzpirat][])

## 0.6.1 - August 15, 2011

### Bug fixes

- [#120][] Remove `guardfile_contents` when re-evaluating so that the Guardfile gets reloaded correctly. ([@mordaroso][])
- [#119][] `Dsl.evaluate_guardfile` uses all groups if none specified. ([@ches][])

## 0.6.0 - August 13, 2011

### Bug fixes

- [#107][] Small spelling fix. ([@dnagir][])
- `Dir.glob` now ignores files that don't need to be watched. ([@rymai][])

### New feature

- [#112][] Add `list` command to CLI. ([@docwhat][])

### Improvements

- [#99][] [OS X] Switch from growl gem to growl_notify gem. ([@johnbintz][])
- [#115][] [Linux] Add `:transient => true` to default libnotify options. ([@zonque][])
- [#95][] Output system commands and options to be executed when in debug mode. ([@uk-ar][] and [@netzpirat][])
- `Guard::Dsl.revaluate_guardfile` has been renamed to `Guard::Dsl.reevaluate_guardfile`. ([@rymai][])
- New CLI options: ([@nestegg][])
  - `watchdir`/`-w` to specify the directory in which Guard should watch for changes,
  - `guardfile`/`-G` to specify an alternate location for the Guardfile to use.
- [#90][] Refactoring of color handling in the `Guard::UI`. ([@stereobooster][])

## 0.5.1 - July 2, 2011

### Bug fix

- Fix `guard show` command. ([@bronson][] and [@thibaudgg][])

## 0.5.0 - July 2, 2011

### New features

- Guard::Ego is now part of Guard, so Guardfile is automagically re-evaluated when modified. ([@thibaudgg][])
- [#91][] Show Guard plugins in Guardfile with the `guard -T`. ([@johnbintz][])

### Improvements

- [#98][] Multiple calls per watch event on linux with rb-inotify. ([@jeffutter][] and [@netzpirat][])
- [#94][] Show backtrace in terminal when a problem with a watch action occurs. ([@capotej][])
- [#88][] Write exception trace in the terminal when a supervised task fail. ([@mcmire][])
- Color in red the "ERROR:" flag when using `UI.error`. ([@rymai][])
- [#79][] and [#82][] Improve INotify support on Linux. ([@Gazer][] and [@yannlugrin][])
- [#12][] and [#86][] Eventually exits with SystemStackError. ([@stereobooster][])
- [#84][] Use RbConfig instead of obsolete and deprecated Config. ([@etehtsea][])
- [#80][] Watching dotfile (hidden files under unix). (reported by [@chrisberkhout][], fixed by [@yannlugrin][])
- Clear the terminal on start when the `:clear` option is given. ([@rymai][])
- Rename home directory Guardfile to `.Guardfile`. ([@tpope][])

## 0.4.2 - June 7, 2011

### Bug fixes

- Fix Guard::Version in ruby 1.8.7 ([@thibaudgg][])
- Fix ([@mislav][]) link in the CHANGELOG (Note: this is a recursive CHANGELOG item). ([@fnichol][])

## 0.4.1 - June 7, 2011

### Improvements

- [#77][] Refactor `get_guard_class` to first try the constant and fallback to require + various tweaks. ([@mislav][])
- Notifier improvement, don't use system notification library if could not be required. ([@yannlugrin][])

## 0.4.0 - June 5, 2011

### Bug fix

- In Ruby < 1.9, `Symbol#downcase` doesn't exist! ([@rymai][])

### New features

- [#73][] Allow DSL's `group` method to accept a Symbol as group name. ([@johnbintz][])
- [#51][] Allow options (like `:priority`) to be passed through to the Notifier. ([@indirect][] and [@netzpirat][])

### Improvement

- [#74][] Add link definitions to make the CHANGELOG more DRY! That's for sure now, we have the cleanest CHANGELOG ever! (even the link definitions are sorted alphabetically!) ([@pcreux][])

## 0.4.0.rc - May 28, 2011

### Bug fixes

- [#69][] Fix typo in README: `Ctr-/` => `Ctr-\`. ([@tinogomes][])
- [#66][] Support for dashes in guard names. ([@johnbintz][])
- Require `guard/ui` because `Guard::Notifier` can be required without full Guard. ([@yannlugrin][])
- Handle quick file (<1s) modification. Avoid to catch modified files without content modification (sha1 checksum). ([@thibaudgg][] and [@netzpirat][])
- Fix `Guard::Notifier` (when growl/libnotify not present). ([@thibaudgg][])
- Fix Rubygems deprecation messages. ([@thibaudgg][])

### New features

- [#67][] Allow Guardfile in `$HOME` folder. ([@hashrocketeer][])
- [#64][] Windows notifications support. ([@stereobooster][])
- [#63][] Refactor listeners to work as a library. ([@niklas][])
- Use `ENV["GUARD_NOTIFY"]` to disable notifications. ([@thibaudgg][])
- Cleaning up all specs. ([@netzpirat][])
- [#60][] Add Windows support. ([@stereobooster][])
- [#58][] Extract code from signal handlers into methods. ([@nicksieger][])
- [#55][] It's now possible to pass `:guardfile` (a Guardfile path) or `:guardfile_contents` (the content of a Guardfile) to `Guard::Dsl.evaluate_guardfile`. Hence this allows the use of `Guard::Dsl.evaluate_guardfile` in a programmatic manner. ([@anithri][], improved by [@rymai][])

## 0.3.4 - April 24, 2011

### Bug fix

- [#41][] Remove useless Bundler requirement. ([@thibaudgg][])

### New features

- Change CHANGELOG from RDOC to Markdown and cleaned it! Let's celebrate! ([@rymai][])
- Change README from RDOC to Markdown! Let's celebrate! ([@thibaudgg][])
- [#48][] Add support for inline Guard classes rather than requiring a gem. ([@jrsacks][])

## 0.3.3 - April 18, 2011

### Bug fix

- Fix `new_modified_files` rerun conditions on `Guard.run_on_change_for_all_guards`. ([@thibaudgg][])

## 0.3.2 - April 17, 2011

### Bug fix

- [#43][] Fix `guard init` command. ([@brainopia][])

## 0.3.1 - April 14, 2011

### Bug fixes

- Return unique filenames from Linux listener. (Marian Schubert)
- `Guard.get_guard_class` return wrong class when loaded nested class. ([@koshigoe][])
- [#35][] Fix open-gem/gem_open dependency problem by using `gem which` to locate guards gem path. (reported by [@thierryhenrio][], fixed by [@thibaudgg][])
- [#38][] and [#39][] Fix an invalid ANSI escape code in `Guard::UI.reset_line`. ([@gix][])

### New feature

- [#28][] New `-n` command line option to disable notifications (Growl / Libnotify). ([@thibaudgg][])

## 0.3.0 - January 19, 2011

### Bug fix

- Avoid launching `run_on_change` guards method when no files matched. `--clear` guard argument is now usable. ([@thibaudgg][])

### New features

- The whole directory is now watched during `run_on_change` to detect new files modifications. ([@thibaudgg][])
- [#26][] New DSL method: `group` allows you to group several guards. New CLI option: `--group group_name` to specify certain groups of guards to start. ([@netzpirat][])
- `watch` patterns are now more strict: strings are matched with `String#==`, `Regexp` are matched with `Regexp#match`. ([@rymai][])
- A deprecation warning is displayed if your `Guardfile` contains `String` that look like `Regexp` (bad!). ([@rymai][])
- It's now possible to return an `Enumerable` in the `watch` optional blocks in the `Guardfile`. ([@rymai][])

### New specs

- `Guard::Watcher`. ([@rymai][])
- [#13][] `Guard::Dsl`. ([@oliamb][])

## 0.2.2 - October 25, 2010

### Bug fix

- [#5][] Avoid creating new copy of `fsevent_watch` every time a file is changed. (reported by [@stouset][], fixed by [@thibaudgg][])

## 0.2.1 - October 24, 2010

### Bug fixes

- [#7][] Fix for Linux support. ([@yannlugrin][])
- [#6][] Locate guard now chomp newline in result path. ([@yannlugrin][])

## 0.2.0 - October 21, 2010

### Bug fixes

- [#3][] `guard init <guard-name>` no more need `Gemfile` but `open_gem` is required now. (reported by [@wereHamster][], fixed by [@thibaudgg][])
- [#2][] 1.8.6 compatibility. (reported by [@veged][], fixed by [@thibaudgg][])
- Remove Growl and Libnotify dependencies. ([@thibaudgg][])

## 0.2.0.beta.1 - October 17, 2010

### New features

- Improve listeners support (`rb-fsevent` and `rb-inotify`). ([@thibaudgg][])
- Add polling listening fallback. ([@thibaudgg][])


<!--- The following link definition list is generated by PimpMyChangelog --->
[#2]: https://github.com/guard/guard/issues/2
[#3]: https://github.com/guard/guard/issues/3
[#5]: https://github.com/guard/guard/issues/5
[#6]: https://github.com/guard/guard/issues/6
[#7]: https://github.com/guard/guard/issues/7
[#12]: https://github.com/guard/guard/issues/12
[#13]: https://github.com/guard/guard/issues/13
[#26]: https://github.com/guard/guard/issues/26
[#28]: https://github.com/guard/guard/issues/28
[#35]: https://github.com/guard/guard/issues/35
[#38]: https://github.com/guard/guard/issues/38
[#39]: https://github.com/guard/guard/issues/39
[#41]: https://github.com/guard/guard/issues/41
[#42]: https://github.com/guard/guard/issues/42
[#43]: https://github.com/guard/guard/issues/43
[#48]: https://github.com/guard/guard/issues/48
[#51]: https://github.com/guard/guard/issues/51
[#55]: https://github.com/guard/guard/issues/55
[#58]: https://github.com/guard/guard/issues/58
[#60]: https://github.com/guard/guard/issues/60
[#63]: https://github.com/guard/guard/issues/63
[#64]: https://github.com/guard/guard/issues/64
[#66]: https://github.com/guard/guard/issues/66
[#67]: https://github.com/guard/guard/issues/67
[#69]: https://github.com/guard/guard/issues/69
[#73]: https://github.com/guard/guard/issues/73
[#74]: https://github.com/guard/guard/issues/74
[#77]: https://github.com/guard/guard/issues/77
[#79]: https://github.com/guard/guard/issues/79
[#80]: https://github.com/guard/guard/issues/80
[#82]: https://github.com/guard/guard/issues/82
[#84]: https://github.com/guard/guard/issues/84
[#86]: https://github.com/guard/guard/issues/86
[#88]: https://github.com/guard/guard/issues/88
[#90]: https://github.com/guard/guard/issues/90
[#91]: https://github.com/guard/guard/issues/91
[#94]: https://github.com/guard/guard/issues/94
[#95]: https://github.com/guard/guard/issues/95
[#97]: https://github.com/guard/guard/issues/97
[#98]: https://github.com/guard/guard/issues/98
[#99]: https://github.com/guard/guard/issues/99
[#107]: https://github.com/guard/guard/issues/107
[#112]: https://github.com/guard/guard/issues/112
[#115]: https://github.com/guard/guard/issues/115
[#119]: https://github.com/guard/guard/issues/119
[#120]: https://github.com/guard/guard/issues/120
[#121]: https://github.com/guard/guard/issues/121
[#128]: https://github.com/guard/guard/issues/128
[#130]: https://github.com/guard/guard/issues/130
[#136]: https://github.com/guard/guard/issues/136
[#137]: https://github.com/guard/guard/issues/137
[#138]: https://github.com/guard/guard/issues/138
[#144]: https://github.com/guard/guard/issues/144
[#145]: https://github.com/guard/guard/issues/145
[#146]: https://github.com/guard/guard/issues/146
[#149]: https://github.com/guard/guard/issues/149
[#150]: https://github.com/guard/guard/issues/150
[#152]: https://github.com/guard/guard/issues/152
[#156]: https://github.com/guard/guard/issues/156
[#157]: https://github.com/guard/guard/issues/157
[#160]: https://github.com/guard/guard/issues/160
[#165]: https://github.com/guard/guard/issues/165
[#166]: https://github.com/guard/guard/issues/166
[#167]: https://github.com/guard/guard/issues/167
[#168]: https://github.com/guard/guard/issues/168
[#173]: https://github.com/guard/guard/issues/173
[#174]: https://github.com/guard/guard/issues/174
[#195]: https://github.com/guard/guard/issues/195
[#213]: https://github.com/guard/guard/issues/213
[#214]: https://github.com/guard/guard/issues/214
[#216]: https://github.com/guard/guard/issues/216
[#218]: https://github.com/guard/guard/issues/218
[#223]: https://github.com/guard/guard/issues/223
[#226]: https://github.com/guard/guard/issues/226
[#227]: https://github.com/guard/guard/issues/227
[#232]: https://github.com/guard/guard/issues/232
[#233]: https://github.com/guard/guard/issues/233
[#236]: https://github.com/guard/guard/issues/236
[#238]: https://github.com/guard/guard/issues/238
[#249]: https://github.com/guard/guard/issues/249
[#250]: https://github.com/guard/guard/issues/250
[#254]: https://github.com/guard/guard/issues/254
[#259]: https://github.com/guard/guard/issues/259
[#260]: https://github.com/guard/guard/issues/260
[#261]: https://github.com/guard/guard/issues/261
[#270]: https://github.com/guard/guard/issues/270
[#274]: https://github.com/guard/guard/issues/274
[#275]: https://github.com/guard/guard/issues/275
[#283]: https://github.com/guard/guard/issues/283
[#298]: https://github.com/guard/guard/issues/298
[#299]: https://github.com/guard/guard/issues/299
[#315]: https://github.com/guard/guard/issues/315
[#316]: https://github.com/guard/guard/issues/316
[#317]: https://github.com/guard/guard/issues/317
[#324]: https://github.com/guard/guard/issues/324
[#327]: https://github.com/guard/guard/issues/327
[#331]: https://github.com/guard/guard/issues/331
[#334]: https://github.com/guard/guard/issues/334
[#342]: https://github.com/guard/guard/issues/342
[#343]: https://github.com/guard/guard/issues/343
[#344]: https://github.com/guard/guard/issues/344
[#345]: https://github.com/guard/guard/issues/345
[#348]: https://github.com/guard/guard/issues/348
[#351]: https://github.com/guard/guard/issues/351
[#352]: https://github.com/guard/guard/issues/352
[#353]: https://github.com/guard/guard/issues/353
[#354]: https://github.com/guard/guard/issues/354
[#358]: https://github.com/guard/guard/issues/358
[#360]: https://github.com/guard/guard/issues/360
[#361]: https://github.com/guard/guard/issues/361
[#362]: https://github.com/guard/guard/issues/362
[#364]: https://github.com/guard/guard/issues/364
[#365]: https://github.com/guard/guard/issues/365
[#367]: https://github.com/guard/guard/issues/367
[#368]: https://github.com/guard/guard/issues/368
[#369]: https://github.com/guard/guard/issues/369
[#372]: https://github.com/guard/guard/issues/372
[#376]: https://github.com/guard/guard/issues/376
[#377]: https://github.com/guard/guard/issues/377
[#378]: https://github.com/guard/guard/issues/378
[#386]: https://github.com/guard/guard/issues/386
[#387]: https://github.com/guard/guard/issues/387
[#389]: https://github.com/guard/guard/issues/389
[@Gazer]: https://github.com/Gazer
[@Maher4Ever]: https://github.com/Maher4Ever
[@alandipert]: https://github.com/alandipert
[@anithri]: https://github.com/anithri
[@ashleyconnor]: https://github.com/ashleyconnor
[@benolee]: https://github.com/benolee
[@brainopia]: https://github.com/brainopia
[@bronson]: https://github.com/bronson
[@cablegram]: https://github.com/cablegram
[@capotej]: https://github.com/capotej
[@ches]: https://github.com/ches
[@chrisberkhout]: https://github.com/chrisberkhout
[@cknadler]: https://github.com/cknadler
[@d1]: https://github.com/d1
[@dgutov]: https://github.com/dgutov
[@dnagir]: https://github.com/dnagir
[@docwhat]: https://github.com/docwhat
[@dyfrgi]: https://github.com/dyfrgi
[@earlonrails]: https://github.com/earlonrails
[@envygeeks]: https://github.com/envygeeks
[@etehtsea]: https://github.com/etehtsea
[@f1sherman]: https://github.com/f1sherman
[@fabioyamate]: https://github.com/fabioyamate
[@fnichol]: https://github.com/fnichol
[@foxycoder]: https://github.com/foxycoder
[@gix]: https://github.com/gix
[@hardipe]: https://github.com/hardipe
[@hashrocketeer]: https://github.com/hashrocketeer
[@hawx]: https://github.com/hawx
[@hron]: https://github.com/hron
[@ianwhite]: https://github.com/ianwhite
[@iljoo]: https://github.com/iljoo
[@indirect]: https://github.com/indirect
[@japgolly]: https://github.com/japgolly
[@jeffutter]: https://github.com/jeffutter
[@jfolkins]: https://github.com/jfolkins
[@johnbintz]: https://github.com/johnbintz
[@jredville]: https://github.com/jredville
[@jrsacks]: https://github.com/jrsacks
[@koshigoe]: https://github.com/koshigoe
[@laserlemon]: https://github.com/laserlemon
[@limeyd]: https://github.com/limeyd
[@madtrick]: https://github.com/madtrick
[@maio]: https://github.com/maio
[@mattgreen]: https://github.com/mattgreen
[@matthijsgroen]: https://github.com/matthijsgroen
[@mcmire]: https://github.com/mcmire
[@mislav]: https://github.com/mislav
[@monocle]: https://github.com/monocle
[@mordaroso]: https://github.com/mordaroso
[@nestegg]: https://github.com/nestegg
[@netzpirat]: https://github.com/netzpirat
[@nickmabry]: https://github.com/nickmabry
[@nicksieger]: https://github.com/nicksieger
[@niklas]: https://github.com/niklas
[@oliamb]: https://github.com/oliamb
[@oreoshake]: https://github.com/oreoshake
[@pcreux]: https://github.com/pcreux
[@philomory]: https://github.com/philomory
[@pirukire]: https://github.com/pirukire
[@rking]: https://github.com/rking
[@rmm5t]: https://github.com/rmm5t
[@royvandewater]: https://github.com/royvandewater
[@rudicode]: https://github.com/rudicode
[@rupert654]: https://github.com/rupert654
[@rymai]: https://github.com/rymai
[@schmurfy]: https://github.com/schmurfy
[@scottdavis]: https://github.com/scottdavis
[@semperos]: https://github.com/semperos
[@spadin]: https://github.com/spadin
[@steakknife]: https://github.com/steakknife
[@stereobooster]: https://github.com/stereobooster
[@stouset]: https://github.com/stouset
[@sunaku]: https://github.com/sunaku
[@sutherland]: https://github.com/sutherland
[@tarsolya]: https://github.com/tarsolya
[@thibaudgg]: https://github.com/thibaudgg
[@thierryhenrio]: https://github.com/thierryhenrio
[@tinogomes]: https://github.com/tinogomes
[@tomas-zemres]: https://github.com/tomas-zemres
[@tpope]: https://github.com/tpope
[@uk-ar]: https://github.com/uk-ar
[@veged]: https://github.com/veged
[@viking]: https://github.com/viking
[@waldo]: https://github.com/waldo
[@wereHamster]: https://github.com/wereHamster
[@yannlugrin]: https://github.com/yannlugrin
[@zonque]: https://github.com/zonque
