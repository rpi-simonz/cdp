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

    --init    create example .cdprc and .private-conf.sh in the current directory

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
            set -- "$(ls -1 "${PROJECTDIR}" | fzf --query="$*" --exact --select-1 --reverse  --no-sort --header=">> Select from the project directories <<" --preview="ls -lG ${PROJECTDIR}/{1}")"
            [[ -z $1 ]] && return 1
            cd "${PROJECTDIR}/$1" || return 1
            set --
            ;;

        -D) shift
            # shellcheck disable=2046 # (Quoting)
            set -- $(ls -ot --time-style=long-iso "${PROJECTDIR}" | awk '{print $5, $6, $7, $8, $9}' | head -11 | tail -10 | fzf --query="$*" --exact --select-1 --reverse --no-sort --header=">> Select from the 10 MRU project directories <<" --preview="ls -ot ${PROJECTDIR}/{3}")
            [[ -z $3 ]] && return 1
            cd "${PROJECTDIR}/$3" || return 1
            set --
            ;;

         .) # No directory selection at all, just stay in the current directory
            # and proceed to the next step checking for .cdprc etc.
            shift ;;

         --init) if [[ -f .cdprc ]] ; then
                     echo "File .cdprc is already existing!"
                 else
                     echo "Creating an example .cdprc file in the current directory now."
                     cat <<EOF-CDPRC > .cdprc
#!/usr/bin/env bash

check_ssh_id() {
    IDFILE="$1"
    [ -f "$IDFILE" ] || return 1
    echo "$2"
    if ! ssh-add -T "$IDFILE" 2>/dev/null ; then
        ssh-add "$IDFILE"
        if [[ $? == 2 ]] ; then
            echo "Connectig to ssh-agent here and try again..."
            eval "$(ssh-agent)"
            ssh-add "$IDFILE"
        fi
    fi
    ssh-add -T "$IDFILE"
}

echo "*** Check/unlock SSH keys (and set possibly more private settings):"
echo ""

# Example:
#     check_ssh_id  ~/.ssh/id_my_github    "Checking ssh key(s) for GitHub ..."
#
# But can/should be set to real values in .private-conf.sh for privacy reasons
# especially if this .cdprc file is tracked by git!
# Then .private-conf.sh can be easily set to be "ignored" in .gitignore.
[[ -f .private-conf.sh ]] && source .private-conf.sh

cat <<EOF


*******************************************************************************

This project directory contains ...

The directory is tracked by git and is connected to the git repo listed below.

*******************************************************************************


EOF

EOF-CDPRC
                 fi

                 if [[ -f .private-conf.sh ]] ; then
                     echo "File .private-conf.sh is already existing!"
                 else
                     echo "Creating an example .private-conf.sh file in the current directory now."
                     cat <<EOF-PRIVATE-CONF > .private-conf.sh
#!/usr/bin/env bash

#echo "Setting user data for git ..."
#git config user.name myname
#git config user.email my-email-address

git config --get user.name
git config --get user.email

echo ""

#check_ssh_id ~/.ssh/the_needed_id   "Checking ssh key(s) for GitHub ..."
EOF-PRIVATE-CONF
                 fi
                 return
                 ;;

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
                echo "cd $PDIR"
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
            read -r -p "Should it be sourced now or viewed before [Y|n|v]? " inp
            inp="${inp:-Y}"
            case "$inp" in
                y|Y|j|J) echo ""
                         source .cdprc
                         break
                         ;;
                      v) less .cdprc
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

