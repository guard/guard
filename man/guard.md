guard(1) -- Guard keeps an eye on your file modifications.
========================================================

## DESCRIPTION

Guard is a command line tool that easily handle events on files modifications.

## SYNOPSIS

guard <command> <options>

## COMMANDS

### start
  Starts Guard. This is the default command if none is provided.

The following options are available:

  `-c`/`--clear`
        Clears the Shell after each change.

  `-n`/`--notify` <flag>
        Disable notifications (Growl or Libnotify depending on your system).
        Note that notifications can also be disabled globally by setting a GUARD_NOTIFY environment variable to false.
        The <flag> part can be passed to guard using true/false or t/f.

  `-d`/`--debug`
        Runs Guard in debug mode.

  `-g`/`--group` <group> ...
        Runs only the groups specified.

  `-w`/`--watchdir` <folder>
        Specify the directory to watch.

  `-G`/`--guardfile` <file>
        Specify a Guardfile by giving its path.

### init [guard]
  Add the requested guard's default Guardfile configuration to the current Guardfile.

### list
  Lists guards that can be used with the `init` command.
  
### -T/show
  List defined groups and guards for the current Guardfile.

## OPTIONS

* `-h`:
  List all of Guard's available commands.

### start

## EXAMPLES

`[bundle exec] guard [start] --watchdir ~/dev --guardfile ~/env/Guardfile --clear --group backend frontend --notify false --debug`

or in a more concise way:

`[bundle exec] guard [start] -w ~/dev -G ~/env/Guardfile -c -g backend frontend -n f -d`

## AUTHORS / CONTRIBUTORS

Thibaud Guillaume-Gentil is the main author.

A list of contributors based on all commits can be found here:
https://github.com/guard/guard/contributors

For an exhaustive list of all the contributors, please see the CHANGELOG:
https://github.com/guard/guard/blob/master/CHANGELOG.md

This manual has been written by Remy Coutable.

## WWW

https://github.com/guard/guard