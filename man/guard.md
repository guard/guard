guard(1) -- Guard keeps an eye on your file modifications.
========================================================

## SYNOPSIS

guard <command> <options>

## DESCRIPTION

Guard is a command line tool that easily handle events on files modifications.

## HOMEPAGE

https://github.com/guard/guard

## OPTIONS

* `-c`, `--clear`:
  Clears the Shell after each change.

* `-n` <flag>, `--notify` <flag>:
  Disable notifications (Growl or Libnotify depending on your system).
  Note that notifications can also be disabled globally by setting a GUARD_NOTIFY environment variable to false.
  The <flag> part can be passed to guard using true/false or t/f.

* `-g` <group> ..., `--group` <group> ...:
  Runs only the groups specified.

* `-d`, `--debug`:
  Runs Guard in debug mode.

* `-h`:
  List all of Guard's available commands.

## COMMANDS

* `start`:
  Starts Guard. This is the default command if none is provided.

* `init` [guard]:
  Add the requested guard's default Guardfile configuration to the current Guardfile.

* `show`, `-T`:
  List defined groups and guards for the current Guardfile.

## EXAMPLES

`[bundle exec] guard --clear --group backend frontend --notify false --debug`

or in a more concise way:

`[bundle exec] guard -c -g backend frontend -n f -d`

## AUTHORS / CONTRIBUTORS

Thibaud Guillaume-Gentil is the main author.

A list of contributors based on all commits can be found here:
https://github.com/guard/guard/contributors

For an exhaustive list of all the contributors, please see the CHANGELOG:
https://github.com/guard/guard/blob/master/CHANGELOG.md
