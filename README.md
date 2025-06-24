# cdp - A TUI directory/project changer with optional autostart script

This is a little *bash* function providing a helper tool for easily `cd`ing
into a target directory, selectable from a list presented by a powerful TUI.

Its name *cdp* comes from "CD Project".

The list of presented directories can be:

  - the contents of the maintained file '${PROJECTFILE}'
  - the alphabetically sorted directories in '${PROJECTDIR}/'
  - the 10 most recently used directories in '${PROJECTDIR}/'

The above variables are set in the script, the defaults are:

    PROJECTDIR=~/projects
    PROJECTFILE=~/.projects

If there is a file `.cdprc` in the target directory, that one is sourced.  
It's like an autostart feature for this directory/project.

Examples will be added soon.


## Usage

```
cdp [option] [filter string]
```

Without any parameters the complete list of saved directories is presented to choose from.
The optional filter string reduces that list to the matching entries. (*fzf* is used for this.)

Options affecting the list of presented directories:

    -d  present sorted directories in '${PROJECTDIR}/' to choose from
    -D  present the 10 MRU directories in '${PROJECTDIR}/' to choose from

The following options are for administrative purposes:

    -e  edit '${PROJECTFILE}'
    -i  insert current directory at '${PROJECTFILE}'s beginning
    -a  append current directory to '${PROJECTFILE}'
    -r  edit rc file .cdprc in the current project directory
    -h  this help text


## Installation

This script is intended to be source'd only, and not executed directly.

Recommended: Source it in your `~/.bashrc`.


The program *fzf* (Fuzzy Finder, [see GitHub](https://github.com/junegunn/fzf)) is required.
Please install it. It should be available in almost every Linux Distribution.
