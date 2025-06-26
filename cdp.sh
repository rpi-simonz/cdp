#!/usr/bin/env bash

cdp() {

    PROJECTDIR=${PROJECTDIR:=~/projects}
    PROJECTFILE=${PROJECTFILE:=~/.projects}

    case "$1" in
     -a|-e|-i)  ;;
        -d|-D)  [[ ! -d "${PROJECTDIR}" ]] && { echo -e "\nError: Directory ${PROJECTDIR} not found." ; return 1 ;} ;;
            *)  [[ ! -s "${PROJECTFILE}" ]] && { echo -e "\nError: Project file ${PROJECTFILE} not found or is empty.\n"; set -- "-h";} ;;
    esac

    case "$1" in
        -h|-\?) cat <<EOF

Present a list of directories ("projects") to 'cd' into, using a powerful TUI.
If there is a file .cdprc in the target directory, that one is sourced.
It's like an autostart feature for this directory/project.

The name *cdp* comes from "CD Project".

The list of presented directories can be:

  - the contents of the maintained projects file '\$PROJECTFILE'
  - the alphabetically sorted directories in '\$PROJECTDIR'
  - the 10 most recently used directories in '\$PROJECTDIR'


Configuration:

There are two environment variables used. They can be set externally.
If not set externally they are set in the script to the following defaults:

    PROJECTDIR=~/projects
    PROJECTFILE=~/.projects


Usage:

    cdp [filter string]
    cdp [option] [dir]

Without any parameters the complete list of saved directories is presented to
choose from. The optional filter string reduces that list to the matching
entries. (fzf is used for this.)

If the given filter string is "." (just a dot) no directory selection is
performed at all, the current directory is kept and any followup actions
are done, e.g. the .cdprc is searched for and optionally sourced.


Options:

Options affecting the list of presented directories:

    -d  present sorted directories in '\$PROJECTDIR' to choose from
    -D  present the 10 MRU directories in '$\PROJECTDIR' to choose from

The following options are for administrative purposes:

    -e        edit '\$PROJECTFILE'
    -i [dir]  insert given or current directory at '\$PROJECTFILE's beginning
    -a [dir]  append given or current directory to '\$PROJECTFILE'
    -r        edit rc file .cdprc in the current project directory
    -h        this help text

EOF
            return
            ;;

        -e) $VISUAL "${PROJECTFILE}"
            return
            ;;

        -r) $VISUAL .cdprc
            return
            ;;

        -i) shift
            if [[ -s "${PROJECTFILE}" ]] ; then
                sed -i "1s|^|${1:-$PWD}\n|" "${PROJECTFILE}"
            else
                echo "${1:-$PWD}" > "${PROJECTFILE}"
            fi
            return
            ;;

        -a) shift
            echo "${1:-$PWD}" >> "${PROJECTFILE}"
            return
            ;;

        -d) shift
            set -- "$(ls -1 "${PROJECTDIR}" | fzf --query="$*" --exact --select-1 --reverse  --no-sort --preview="ls -lG ${PROJECTDIR}/{1}")"
            [[ -z $1 ]] && return 1
            cd "${PROJECTDIR}/$1" || return 1
            set --
            ;;

        -D) shift
            set -- "$(ls -ltG "${PROJECTDIR}" | head -11 | tail -10 | fzf --query="$*" --exact --select-1 --reverse  --no-sort --preview="ls -ltG ${PROJECTDIR}/{8}")"
            [[ -z $8 ]] && return 1
            cd "${PROJECTDIR}/$8" || return 1
            set --
            ;;

         .) # No directory selection at all, just stay in the current directory
            # and proceed to the next step checking for .cdprc etc.
            shift ;;

         *)
            set -- "$(grep -v '^\s*$' "${PROJECTFILE}" | fzf --query="$*" --exact --select-1 --reverse --no-sort --preview='ls -lA {1}')"
            PDIR="$1"
            [[ -z "$PDIR" ]] && return 1
            shift
            [[ ! -d "${PDIR}" ]] && { echo "Directory ${PDIR} not found." ; return 1 ;}
            if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
                echo ""
                echo "Script isn't sourced! So 'cd $PDIR' won't work as expected."
                echo "Exiting now."
                return 1
            else
                cd "$PDIR" || return 1
            fi
            ;;
    esac

    if [[ -f .cdprc ]] ; then
        echo ""
        echo "***************************************"
        echo "* Automatic init file '.cdprc' found: *"
        echo "***************************************"
        echo ""
        while true ; do
            read -r -e -p "Should it be sourced now or viewed before [Y|n|v]? " -i "Y" inp
            case "$inp" in
                y|Y|j|J) source .cdprc
                         break
                         ;;
                   v|Yv) # Note: Yv is intentional here! Just for convenience.
                         less .cdprc
                         ;;
                      *) echo ".cdprc has NOT been sourced!"
                         break
                         ;;
            esac
        done
    fi

    if [[ -d .hg ]] ; then
        echo -e "\n========== hg =================================================="
        #hg heads  # not sure yet if this remains commented out, gets activated or deleted
        echo -e "\n---------- hg sum\n"
        hg sum
        echo -e "\n================================================================\n"
    fi

    if [[ -d .git ]] ; then
        echo -e "\n========== git ================================================="
        echo -e "\n---------- git remote -v\n"
        git remote -v
        echo -e "\n---------- git show --no-patch\n"
        git show --no-patch
        echo -e "\n---------- git fetch -v ; git status\n"
        git fetch -v
        echo ""
        git status
        echo -e "\n================================================================\n"
    fi

    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "////////////////////////////////////////////////////////////////////"
    echo "// This script defines the function 'cdp()' (aka \"cd project\").   //"
    echo "// It is intended to be source'd only, and not executed directly. //"
    echo "// Please source this script. Recommended: In your ~/.bashrc.     //"
    echo "////////////////////////////////////////////////////////////////////"

    if ! command -pv fzf >/dev/null; then
        echo "The program 'fzf' (Fuzzy Finder) is required."
        echo "Please install it, usually using your distros package management."
        exit 8
    fi

    cdp "$@"
fi

