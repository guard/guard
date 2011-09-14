## 0.7.0 - September 14, 2011

## 0.7.0.rc1 - September 5, 2011

### Major Changes

- Posix Signals handlers (`Ctrl-C`, `Ctrl-\` and `Ctrl-Z`) are no more supported and replaced by `$stdin.gets`. Please refer to the "Interactions" section in the README for more information. ([@thibaudgg][])
- JRuby & Rubinius support (beta). ([@thibaudgg][] and [@netzpirat][])

### New feature:

- Pull request [#42](https://github.com/guard/guard/pull/42): New DSL method: `callback` allows you to execute arbitrary code before or after any of the `start`, `stop`, `reload`, `run_all` and `run_on_change` guards' method. New [Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for documenting it. ([@monocle][] & [@rymai][])
- Ability to 'pause' files modification listening. Please refer to the "Interactions" section in the README for more information. ([@thibaudgg][])

### Improvement:

- Remove the need to scan the whole directory after guard's `run_on_change` method. ([@thibaudgg][])

## 0.6.3 - September 1, 2011

### New features:

- Pull request [#130](https://github.com/guard/guard/pull/130): Adds `ignore_paths` method to DSL. ([@ianwhite][])
- Pull request [#128](https://github.com/guard/guard/pull/128): Users can add additional settings to `~/.guard.rb` that augment the existing Guardfile. ([@tpope][])

## 0.6.2 - August 17, 2011

### Bugs fixes:

- Re-add the possibility to use the `growl` gem since the `growl_notify` gem this is currently known to not work in conjunction with Spork. ([@netzpirat][])
- Ensure that scoped groups and group name are symbolized before checking for inclusion. ([@rymai][])

### New features:

- Groups are now stored in a `@groups` variable (will be used for future features). ([@rymai][])
- Guards will now receive their group in the options hash at initialization (will be used for future features). ([@rymai][])

### Improvement:

- Explain the growl/growl_notify differences in the README. ([@netzpirat][])

## 0.6.1 - August 15, 2011

### Bugs fixes:

- Pull request [#120](https://github.com/guard/guard/pull/120): remove `guardfile_contents` when re-evaluating so that the Guardfile gets reloaded correctly. ([@mordaroso][])
- Pull request [#119](https://github.com/guard/guard/pull/119): `Dsl.evaluate_guardfile` uses all groups if none specified. ([@ches][])

## 0.6.0 - August 13, 2011

### Bugs fixes:

- Pull request [#107](https://github.com/guard/guard/pull/107): Small spelling fix. ([@dnagir][])
- `Dir.glob` now ignores files that don't need to be watched. ([@rymai][])

### New features:

- Pull request [#112](https://github.com/guard/guard/pull/112): Add `list` command to CLI. ([@docwhat][])

### Improvements:

- Pull request [#99](https://github.com/guard/guard/pull/99): [OS X] Switch from growl gem to growl_notify gem. ([@johnbintz][])
- Pull request [#115](https://github.com/guard/guard/pull/115): [Linux] Add `:transient => true` to default libnotify options. ([@zonque][])
- Pull request [#95](https://github.com/guard/guard/pull/95): Output system commands and options to be executed when in debug mode. ([@uk-ar][] and [@netzpirat][])
- `Guard::Dsl.revaluate_guardfile` has been renamed to `Guard::Dsl.reevaluate_guardfile`. ([@rymai][])
- New CLI options: ([@nestegg][])
  - `watchdir`/`-w` to specify the directory in which Guard should watch for changes,
  - `guardfile`/`-G` to specify an alternate location for the Guardfile to use.
- Pull request [#90](https://github.com/guard/guard/pull/90): Refactoring of color handling in the `Guard::UI`. ([@stereobooster][])

## 0.5.1 - July 2, 2011

### Bugs fixes:

- Fixed `guard show` command. ([@bronson][] & [@thibaudgg][])

## 0.5.0 - July 2, 2011

### New features:

- Guard::Ego is now part of Guard, so Guardfile is automagically re-evaluated when modified. ([@thibaudgg][])
- Pull request [#91](https://github.com/guard/guard/pull/91): Show Guards in Guardfile with the `guard -T`. ([@johnbintz][])

### Improvements:

- Issue [#98](https://github.com/guard/guard/issues/98): Multiple calls per watch event on linux with rb-inotify. ([@jeffutter][] & [@netzpirat][])
- Pull request [#94](https://github.com/guard/guard/pull/94): Show backtrace in terminal when a problem with a watch action occurs. ([@capotej][])
- Pull request [#88](https://github.com/guard/guard/pull/88): Write exception trace in the terminal when a supervised task fail. ([@mcmire][])
- Color in red the "ERROR:" flag when using `UI.error`. ([@rymai][])
- Issue [#79](https://github.com/guard/guard/issues/79) and Pull request [#82](https://github.com/guard/guard/pull/82): Improve INotify support on Linux. ([@Gazer][] & [@yannlugrin][])
- Issue [#12](https://github.com/guard/guard/issues/12) and Pull request [#86](https://github.com/guard/guard/pull/86): Eventually exits with SystemStackError. ([@stereobooster][])
- Pull request [#84](https://github.com/guard/guard/pull/84): Use RbConfig instead of obsolete and deprecated Config. ([@etehtsea][])
- Pull request [#80](https://github.com/guard/guard/pull/80): Watching dotfile (hidden files under unix). (reported by [@chrisberkhout][], fixed by [@yannlugrin][])
- Clear the terminal on start when the `:clear` option is given. ([@rymai][])
- Rename home directory Guardfile to `.Guardfile`. ([@tpope][])

## 0.4.2 - June 7, 2011

### Bugs fixes:

- Fixed Guard::Version in ruby 1.8.7 ([@thibaudgg][])
- Fix ([@mislav][]) link in CHANGELOG (Note: this is a recursive CHANGELOG item). ([@fnichol][])

## 0.4.1 - June 7, 2011

### Improvements:

- Pull request [#77](https://github.com/guard/guard/pull/77): Refactor `get_guard_class` to first try the constant and fallback to require + various tweaks. ([@mislav][])
- Notifier improvement, don't use system notification library if could not be required. ([@yannlugrin][])

## 0.4.0 - June 5, 2011

### Bugs fixes:

- In Ruby < 1.9, `Symbol#downcase` doesn't exist! ([@rymai][])

### New features:

- Pull request [#73](https://github.com/guard/guard/pull/73): Allow DSL's `group` method to accept a Symbol as group name. ([@johnbintz][])
- Pull request [#51](https://github.com/guard/guard/pull/51): Allow options (like `:priority`) to be passed through to the Notifier. ([@indirect][] & [@netzpirat][])

### Improvements:

- Pull request [#74](https://github.com/guard/guard/pull/74): Added link definitions to make the CHANGELOG more DRY! That's for sure now, we have the cleanest CHANGELOG ever! (even the link definitions are sorted alphabetically!) ([@pcreux][])

## 0.4.0.rc - May 28, 2011

### Bugs fixes:

- Pull request [#69](https://github.com/guard/guard/pull/69): Fixed typo in README: `Ctr-/` => `Ctr-\`. ([@tinogomes][])
- Pull request [#66](https://github.com/guard/guard/pull/66): Support for dashes in guard names. ([@johnbintz][])
- Require `guard/ui` because `Guard::Notifier` can be required without full Guard. ([@yannlugrin][])
- Handled quick file (<1s) modification. Avoid to catch modified files without content modification (sha1 checksum). ([@thibaudgg][] & [@netzpirat][])
- Fixed `Guard::Notifier` (when growl/libnotify not present). ([@thibaudgg][])
- Fixed Rubygems deprecation messages. ([@thibaudgg][])

### New features:

- Pull request [#67](https://github.com/guard/guard/pull/67): Allow Guardfile in `$HOME` folder. ([@hashrocketeer][])
- Pull request [#64](https://github.com/guard/guard/pull/64): Windows notifications support. ([@stereobooster][])
- Pull request [#63](https://github.com/guard/guard/pull/63): Refactor listeners to work as a library. ([@niklas][])
- Use `ENV["GUARD_NOTIFY"]` to disable notifications. ([@thibaudgg][])
- Cleaning up all specs. ([@netzpirat][])
- Pull request [#60](https://github.com/guard/guard/pull/60): Added Windows support. ([@stereobooster][])
- Pull request [#58](https://github.com/guard/guard/pull/58): Extract code from signal handlers into methods. ([@nicksieger][])
- Pull request [#55](https://github.com/guard/guard/pull/55): It is now possible to pass `:guardfile` (a Guardfile path) or `:guardfile_contents` (the content of a Guardfile) to `Guard::Dsl.evaluate_guardfile`. Hence this allows the use of `Guard::Dsl.evaluate_guardfile` in a programmatic manner. ([@anithri][], improved by [@rymai][])


## 0.3.4 - April 24, 2011

### Bugs fixes:

- Issue [#41](https://github.com/guard/guard/issues/41): Removed useless Bundler requirement. ([@thibaudgg][])

### New features:

- Changed CHANGELOG from RDOC to Markdown and cleaned it! Let's celebrate! ([@rymai][])
- Changed README from RDOC to Markdown! Let's celebrate! ([@thibaudgg][])
- Issue [#48](https://github.com/guard/guard/issues/48): Adding support for inline Guard classes rather than requiring a gem. ([@jrsacks][])


## 0.3.3 - April 18, 2011

### Bugs fixes:

- Fixed `new_modified_files` rerun conditions on `Guard.run_on_change_for_all_guards`. ([@thibaudgg][])


## 0.3.2 - April 17, 2011

### Bugs fixes:

- Pull request [#43](https://github.com/guard/guard/pull/43): Fixed `guard init` command. ([@brainopia][])


## 0.3.1 - April 14, 2011

### Bugs fixes:

- Return unique filenames from Linux listener. (Marian Schubert)
- `Guard.get_guard_class` return wrong class when loaded nested class. ([@koshigoe][])
- Issue [#35](https://github.com/guard/guard/issues/35): Fixed open-gem/gem_open dependency problem by using `gem which` to locate guards gem path. (reported by [@thierryhenrio][], fixed by [@thibaudgg][])
- Issue [#38](https://github.com/guard/guard/issues/38) & Pull request [#39](https://github.com/guard/guard/issues/39): Fixed an invalid ANSI escape code in `Guard::UI.reset_line`. ([@gix][])

### New features:

- Issue [#28](https://github.com/guard/guard/issues/28): New `-n` command line option to disable notifications (Growl / Libnotify). ([@thibaudgg][])


## 0.3.0 - January 19, 2011

### Bugs fixes:

- Avoid launching `run_on_change` guards method when no files matched. `--clear` guard argument is now usable. ([@thibaudgg][])

### New features:

- The whole directory is now watched during `run_on_change` to detect new files modifications. ([@thibaudgg][])
- Pull request [#26](https://github.com/guard/guard/pull/26): New DSL method: `group` allows you to group several guards. New CLI option: `--group group_name` to specify certain groups of guards to start. ([@netzpirat][])
- `watch` patterns are now more strict: strings are matched with `String#==`, `Regexp` are matched with `Regexp#match`. ([@rymai][])
- A deprecation warning is displayed if your `Guardfile` contains `String` that look like `Regexp` (bad!). ([@rymai][])
- It's now possible to return an `Enumerable` in the `watch` optional blocks in the `Guardfile`. ([@rymai][])

### New specs:

- `Guard::Watcher`. ([@rymai][])
- Pull request [#13](https://github.com/guard/guard/pull/13): `Guard::Dsl`. ([@oliamb][])


## 0.2.2 - October 25, 2010

### Bugs fixes:

- Issue [#5](https://github.com/guard/guard/issues/5): avoid creating new copy of `fsevent_watch` every time a file is changed. (reported by [@stouset][], fixed by [@thibaudgg][])


## 0.2.1 - October 24, 2010

### Bugs fixes:

- Pull request [#7](https://github.com/guard/guard/pull/7): Fixes for Linux support. ([@yannlugrin][])
- Pull request [#6](https://github.com/guard/guard/pull/6): Locate guard now chomp newline in result path. ([@yannlugrin][])


## 0.2.0 - October 21, 2010

### Bugs fixes:

- Issue [#3](https://github.com/guard/guard/issues/3): `guard init <guard-name>` no more need `Gemfile` but `open_gem` is required now. (reported by [@wereHamster][], fixed by [@thibaudgg][])
- Issue [#2](https://github.com/guard/guard/issues/2): 1.8.6 compatibility. (reported by [@veged][], fixed by [@thibaudgg][])
- Removes Growl & Libnotify dependencies. ([@thibaudgg][])


## 0.2.0.beta.1 - October 17, 2010

### New features:

- Improved listeners support (`rb-fsevent` & `rb-inotify`). ([@thibaudgg][])
- Added polling listening fallback. ([@thibaudgg][])

[@anithri]: https://github.com/anithri
[@brainopia]: https://github.com/brainopia
[@bronson]: https://github.com/bronson
[@capotej]: https://github.com/capotej
[@ches]: https://github.com/ches
[@chrisberkhout]: https://github.com/chrisberkhout
[@dnagir]: https://github.com/dnagir
[@docwhat]: https://github.com/docwhat
[@etehtsea]: https://github.com/etehtsea
[@fnichol]: https://github.com/fnichol
[@Gazer]: https://github.com/Gazer
[@gix]: https://github.com/gix
[@hashrocketeer]: https://github.com/hashrocketeer
[@ianwhite]: https://github.com/ianwhite
[@indirect]: https://github.com/indirect
[@jeffutter]: https://github.com/jeffutter
[@johnbintz]: https://github.com/johnbintz
[@jrsacks]: https://github.com/jrsacks
[@koshigoe]: https://github.com/koshigoe
[@mcmire]: https://github.com/mcmire
[@mislav]: https://github.com/mislav
[@monocle]: https://github.com/monocle
[@mordaroso]: https://github.com/mordaroso
[@nestegg]: https://github.com/nestegg
[@netzpirat]: https://github.com/netzpirat
[@nicksieger]: https://github.com/nicksieger
[@niklas]: https://github.com/niklas
[@oliamb]: https://github.com/oliamb
[@pcreux]: https://github.com/pcreux
[@rymai]: https://github.com/rymai
[@stereobooster]: https://github.com/stereobooster
[@stouset]: https://github.com/stouset
[@thibaudgg]: https://github.com/thibaudgg
[@thierryhenrio]: https://github.com/thierryhenrio
[@tinogomes]: https://github.com/tinogomes
[@tpope]: https://github.com/tpope
[@uk-ar]: https://github.com/uk-ar
[@veged]: https://github.com/veged
[@wereHamster]: https://github.com/wereHamster
[@yannlugrin]: https://github.com/yannlugrin
[@zonque]: https://github.com/zonque
