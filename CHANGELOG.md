## 0.4.0.rc - May 28, 2011

### Bugs fixes:

- Pull request [#69](https://github.com/guard/guard/pull/69): Fixed typo in README: Ctr-/ => Ctr-\\. ([@tinogomes](https://github.com/tinogomes))
- Pull request [#66](https://github.com/guard/guard/pull/66): Support for dashes in guard names. ([@johnbintz](https://github.com/johnbintz))
- Require `guard/ui` because `Guard::Notifier` can be required without full Guard. ([@yannlugrin](https://github.com/yannlugrin))
- Handled quick file (<1s) modification. Avoid to catch modified files without content modification (sha1 checksum). ([@thibaudgg](https://github.com/thibaudgg) and [@netzpirat](https://github.com/netzpirat))
- Fixed `Guard::Notifier` (when growl/libnotify not present). ([@thibaudgg](https://github.com/thibaudgg))
- Fixed Rubygems deprecation messages. ([@thibaudgg](https://github.com/thibaudgg))

### New features:

- Pull request [#67](https://github.com/guard/guard/pull/67): Allow Guardfile in `$HOME` folder. ([@hashrocketeer](https://github.com/hashrocketeer))
- Pull request [#64](https://github.com/guard/guard/pull/64): Windows notifications support. ([@stereobooster](https://github.com/stereobooster))
- Pull request [#63](https://github.com/guard/guard/pull/63): Refactor listeners to work as a library. ([@niklas](https://github.com/niklas))
- Use `ENV["GUARD_NOTIFY"]` to disable notifications. ([@thibaudgg](https://github.com/thibaudgg))
- Cleaning up all specs. ([@netzpirat](https://github.com/netzpirat))
- Pull request [#60](https://github.com/guard/guard/pull/60): Added Windows support. ([@stereobooster](https://github.com/stereobooster))
- Pull request [#58](https://github.com/guard/guard/pull/58): Extract code from signal handlers into methods. ([@nicksieger](https://github.com/nicksieger))
- Pull request [#55](https://github.com/guard/guard/pull/55): It is now possible to pass `:guardfile` (a Guardfile path) or `:guardfile_contents` (the content of a Guardfile) to `Guard::Dsl.evaluate_guardfile`. Hence this allows the use of `Guard::Dsl.evaluate_guardfile` in a programmatic manner. ([@anithri](https://github.com/anithri), improved by [@rymai](https://github.com/rymai))


## 0.3.4 - April 24, 2011

### Bugs fixes:

- Issue [#41](https://github.com/guard/guard/issues/41): Removed useless Bundler requirement. ([@thibaudgg](https://github.com/thibaudgg))

### New features:

- Changed CHANGELOG from RDOC to Markdown and cleaned it! Let's celebrate! ([@rymai](https://github.com/rymai))
- Changed README from RDOC to Markdown! Let's celebrate! ([@thibaudgg](https://github.com/thibaudgg))
- Issue [#48](https://github.com/guard/guard/issues/48): Adding support for inline Guard classes rather than requiring a gem. ([@jrsacks](https://github.com/jrsacks))


## 0.3.3 - April 18, 2011

### Bugs fixes:

- Fixed `new_modified_files` rerun conditions on `Guard.run_on_change_for_all_guards`. ([@thibaudgg](https://github.com/thibaudgg))


## 0.3.2 - April 17, 2011

### Bugs fixes:

- Pull request [#43](https://github.com/guard/guard/pull/43): Fixed `guard init` command. ([@brainopia](https://github.com/brainopia))


## 0.3.1 - April 14, 2011

### Bugs fixes:

- Return unique filenames from Linux listener. (Marian Schubert)
- `Guard.get_guard_class` return wrong class when loaded nested class. ([@koshigoe](https://github.com/koshigoe))
- Issue [#35](https://github.com/guard/guard/issues/35): Fixed open-gem/gem_open dependency problem by using `gem which` to locate guards gem path. (reported by [@thierryhenrio](https://github.com/thierryhenrio), fixed by [@thibaudgg](https://github.com/thibaudgg))
- Issue [#38](https://github.com/guard/guard/issues/38) & Pull request [#39](https://github.com/guard/guard/issues/39): Fixed an invalid ANSI escape code in `Guard::UI.reset_line`. ([@gix](https://github.com/gix))

### New features:

- Issue [#28](https://github.com/guard/guard/issues/28): New `-n` command line option to disable notifications (Growl / Libnotify). ([@thibaudgg](https://github.com/thibaudgg))


## 0.3.0 - January 19, 2011

### Bugs fixes:

- Avoid launching `run_on_change` guards method when no files matched. `--clear` guard argument is now usable. ([@thibaudgg](https://github.com/thibaudgg))

### New features:

- The whole directory is now watched during `run_on_change` to detect new files modifications. ([@thibaudgg](https://github.com/thibaudgg))
- Pull request [#26](https://github.com/guard/guard/pull/26): New DSL method: `group` allows you to group several guards. New CLI option: `--group group_name` to specify certain groups of guards to start. ([@netzpirat](https://github.com/netzpirat))
- `watch` patterns are now more strict: strings are matched with `String#==`, `Regexp` are matched with `Regexp#match`. ([@rymai](https://github.com/rymai))
- A deprecation warning is displayed if your `Guardfile` contains `String` that look like `Regexp` (bad!). ([@rymai](https://github.com/rymai))
- It's now possible to return an `Enumerable` in the `watch` optional blocks in the `Guardfile`. ([@rymai](https://github.com/rymai))

### New specs:

- `Guard::Watcher`. ([@rymai](https://github.com/rymai))
- Pull request [#13](https://github.com/guard/guard/pull/13): `Guard::Dsl`. ([@oliamb](https://github.com/oliamb))


## 0.2.2 - October 25, 2010

### Bugs fixes:

- Issue [#5](https://github.com/guard/guard/issues/5): avoid creating new copy of `fsevent_watch` every time a file is changed. (reported by [@stouset](https://github.com/stouset), fixed by [@thibaudgg](https://github.com/thibaudgg))


## 0.2.1 - October 24, 2010

### Bugs fixes:

- Pull request [#7](https://github.com/guard/guard/pull/7): Fixes for Linux support. ([@yannlugrin](https://github.com/yannlugrin)))
- Pull request [#6](https://github.com/guard/guard/pull/6): Locate guard now chomp newline in result path. ([@yannlugrin](https://github.com/yannlugrin)))


## 0.2.0 - October 21, 2010

### Bugs fixes:

- Issue [#3](https://github.com/guard/guard/issues/3): `guard init <guard-name>` no more need `Gemfile` but `open_gem` is required now. (reported by [@wereHamster](https://github.com/wereHamster), fixed by [@thibaudgg](https://github.com/thibaudgg))
- Issue [#2](https://github.com/guard/guard/issues/2): 1.8.6 compatibility. (reported by [@veged](https://github.com/veged), fixed by [@thibaudgg](https://github.com/thibaudgg))
- Removes Growl & Libnotify dependencies. ([@thibaudgg](https://github.com/thibaudgg))


## 0.2.0.beta.1 - October 17, 2010

### New features:

- Improved listeners support (`rb-fsevent` & `rb-inotify`). ([@thibaudgg](https://github.com/thibaudgg))
- Added polling listening fallback. ([@thibaudgg](https://github.com/thibaudgg))