#!/usr/bin/env bash
#
# Filename: download-updates.bash
# Version: Linux download scripts, version 1.21-ESR
# Release date: 2021-07-24
# Development branch: esr-11.9
# Supported version: WSUS Offline Update, Community Edition 11.9.10 (b16)
#
# Copyright (C) 2016-2021 Hartmut Buhrmester
#                         <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
#
# License
#
#     This file is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published
#     by the Free Software Foundation, either version 3 of the License,
#     or (at your option) any later version.
#
#     This file is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     General Public License for more details.
#
#     You should have received a copy of the GNU General
#     Public License along with this program.  If not, see
#     <http://www.gnu.org/licenses/>.
#
# Description
#
#     An analog of the Windows script DownloadUpdates.cmd as a shell
#     script. Use this script to download updates for Microsoft Windows
#     and Office.
#
#     This script is meant to run without user interaction. It will only
#     ask for confirmation, if there is a new version of WSUS Offline
#     Update available, which can be installed. Even this question will
#     default to "no" after 30 seconds. This means, that the script
#     download-updates.bash could be used in cron jobs or similar
#     automated tasks.
#
#     The interactive setup is done by the accompanying script
#     setup-downloads.bash .
#
#     USAGE
#        ./download-updates.bash UPDATE[,UPDATE...] \
#                                LANGUAGE[,LANGUAGE...] \
#                                [OPTIONS]
#
#     UPDATE
#         w60           Windows Server 2008, 32-bit
#         w60-x64       Windows Server 2008, 64-bit
#         w61           Windows 7, 32-bit
#         w61-x64       Windows 7 / Server 2008 R2, 64-bit
#         w62-x64       Windows Server 2012, 64-bit            (deprecated)
#         w63           Windows 8.1, 32-bit                    (deprecated)
#         w63-x64       Windows 8.1 / Server 2012 R2, 64-bit   (deprecated)
#         w100          Windows 10, 32-bit                     (deprecated)
#         w100-x64      Windows 10 / Server 2016/2019, 64-bit  (deprecated)
#         o2k13         Office 2013, 32-bit                    (deprecated)
#         o2k13-x64     Office 2013, 32-bit and 64-bit         (deprecated)
#         o2k16         Office 2016, 32-bit                    (deprecated)
#         o2k16-x64     Office 2016, 32-bit and 64-bit         (deprecated)
#         all           All Windows and Office updt, 32/64-bit (deprecated)
#         all-x86       All Windows and Office updates, 32-bit (deprecated)
#         all-x64       All Windows and Office updates, 64-bit (deprecated)
#         all-win       All Windows updates, 32-bit and 64-bit (deprecated)
#         all-win-x86   All Windows updates, 32-bit            (deprecated)
#         all-win-x64   All Windows updates, 64-bit            (deprecated)
#         all-ofc       All Office updates, 32-bit and 64-bit  (deprecated)
#         all-ofc-x86   All Office updates, 32-bit             (deprecated)
#
#         Notes: Multiple updates can be joined to a comma-separated
#         list like "w63,w63-x64".
#
#     LANGUAGE
#         deu    German
#         enu    English
#         ara    Arabic
#         chs    Chinese (Simplified)
#         cht    Chinese (Traditional)
#         csy    Czech
#         dan    Danish
#         nld    Dutch
#         fin    Finnish
#         fra    French
#         ell    Greek
#         heb    Hebrew
#         hun    Hungarian
#         ita    Italian
#         jpn    Japanese
#         kor    Korean
#         nor    Norwegian
#         plk    Polish
#         ptg    Portuguese
#         ptb    Portuguese (Brazil)
#         rus    Russian
#         esn    Spanish
#         sve    Swedish
#         trk    Turkish
#
#         Note: Multiple languages can be joined to a comma-separated
#         list like "deu,enu".
#
#     OPTIONS
#        -includesp
#             Include Service Packs
#
#        -includecpp
#             Include Visual C++ runtime libraries
#
#        -includedotnet
#             Include .NET Frameworks: localized installation files
#             and updates
#
#        -includewddefs
#             Windows Defender definition updates for the built-in
#             Defender of Windows Vista and 7
#
#        -includemsse
#             Microsoft Security Essentials: localized installation files
#             and virus definition updates. Microsoft Security Essentials
#             is an optional installation for Windows Vista and 7.
#
#        -includewddefs8
#             Windows Defender definition updates for the built-in
#             Defender of Windows 8, 8.1 and 10
#
#             These are the same virus definition updates as for Microsoft
#             Security Essentials, and they are downloaded to the same
#             directories, but without the localized installers.
#
#             Therefore, "wddefs8" is a subset of "msse", and you should
#             use -includemsse instead for the internal lists "all" and
#             "all-win".

# ========== Formatting ===================================================

# Comments in shell scripts are formatted to a line length of 75
# characters with:
#
# fmt -p "#"
#
# Lists with a hanging indentation can be formatted with the "crown
# margin" option:
#
# fmt -p "#" -c

# ========== Shell options ================================================

# The option errexit is redundant, if a trap on ERR is defined, which
# also exits the script.
#
# The option errtrace is needed for a trap on ERR to be inherited by
# functions.

set -o nounset
#set -o errexit
set -o errtrace
set -o pipefail
shopt -s nocasematch

# The shell option lastpipe is used to export variables from the last
# section of a pipe. It is used in the function download_from_gitlab.
#
# According to /usr/share/doc/bash/changelog.gz, the option lastpipe was
# introduced in bash-4.2-alpha. Therefore, the Linux download scripts
# now require bash 4.2 and Debian 7 Wheezy or later.
shopt -s lastpipe

# ========== Environment variables ========================================

# Setting LC_ALL to C sets LC_COLLATE, LC_CTYPE and LC_MESSAGES to the
# standard locale C. Messages are printed in American English. It is not
# necessary to set the environment variable LANG, and this may actually
# cause an error. See "man grep" for a description.
#
# LC_ALL and LC_COLLATE influence the sort order of GNU sort and join. To
# stabilize the sort order of some files, a traditional sort order using
# byte values should be used by setting LC_ALL=C.

export LC_ALL=C

# ========== Configuration ================================================

# Configuration variables are placed at the top of the script for easy
# customization. The script version and release date are considered
# read-only. The other variables should still be writable to allow
# libraries to test them and provide standard parameters for other
# scripts.

readonly script_version="1.21-ESR"
readonly release_date="2021-07-24"

# The version of WSUS Offline Update is extracted from the script
# DownloadUpdates.cmd, after resolving the current working directory.

wsusoffline_version=""

# ========== Global variables =============================================

# Global variables are used in several places. They are usually
# initialized to a default value and filled in later by the script.

command_line="$0 $*"
command_line_parameters=( "$@" )
kernel_name=""
kernel_details=""
hardware_architecture=""

# The home directory of the Linux scripts and other directories are set
# to absolute paths after resolving the current working directory.

canonical_name=""         # normalized, absolute pathname of the script
script_name=""            # filename of the script
home_directory=""         # home directory of the Linux download scripts
wsusoffline_directory=""  # enclosing wsusoffline directory
cache_dir=""              # cache directory for extracted package.xml
log_dir=""                # log directory
logfile=""                # log file with an absolute pathname
timestamp_dir=""          # timestamps for the "same_day" function

# Create a temporary directory:

if type -P mktemp >/dev/null
then
    temp_dir="$(mktemp -d /tmp/download-updates.XXXXXX)"
else
    temp_dir="/tmp/download-updates.temp"
    mkdir -p "${temp_dir}"
fi

# ========== Preferences  =================================================

# These are the default settings for the optional preferences file.
#
# The preferences file is provided as a template
# "preferences-template.bash". To use it, it must be copied or renamed to
# "preferences.bash". This is meant as a simple way to protect customized
# settings from being overwritten on each update of the Linux download
# scripts.
#
# Since the preferences file is optional, the default settings are
# supplied here. Changes should be made to the file preferences.bash. All
# settings are explained in that file.
#
# Note: Some preferences have been moved to the libraries or tasks,
# where they are first used.

# Boolean options are set to either "enabled" or "disabled":

prefer_seconly="disabled"
check_for_self_updates="enabled"
unattended_updates="disabled"
use_file_signature_verification="disabled"
use_integrity_database="enabled"
exit_on_configuration_problems="enabled"

# ========== Traps ========================================================

# Traps are functions, which are automatically invoked on certain events.
#
# A trap on ERR is automatically called, if an external command returns
# an error code, which is not tested in a conditional statement. The
# conditions to call the error handler seem to be the same as for the
# shell option errexit.
#
# An error handler does not necessarily need to exit the script, but
# could be used for some exception handling to recover from errors.
#
# If the error handler does exit the script, then it completely replaces
# the shell option errexit.
#
# The function error_handler is used here, to create two backtraces,
# using the array ${FUNCNAME[*]} and the internal command "caller".

function error_handler ()
{
    local -i result_code="$?"
    printf '%s\n' "Failure: unhandled error ${result_code}"

    # The indexed array FUNCNAME has the calling chain of all functions,
    # with the top level code called "main". This is why there is no
    # function "main" in the script.
    printf '%s\n' "Backtrace: ${FUNCNAME[*]}"

    # The bash internal command "caller" moves backwards through the
    # calling chain. It is typically used with a bash debugger, but can
    # also be used alone.
    local previous_command=""
    local -i depth="0"
    while previous_command="$(caller ${depth})"
    do
        printf '%s\n' "Caller ${depth}: ${previous_command}"
        depth="$(( depth + 1 ))"
    done

    exit "${result_code}"
} 1>&2
trap error_handler ERR

# An exception handler is triggered by signals, which are sent by "kill"
# or simply by typing Ctrl-C.

function exception_handler ()
{
    local -i result_code="$?"
    echo "Quitting because of Ctrl-C or similar exception..."
    exit "${result_code}"
} 1>&2
trap exception_handler SIGHUP SIGINT SIGPIPE SIGTERM

# The exit handler is called whenever the script exits, either by a
# normal exit or triggered by some error.

function exit_handler ()
{
    local -i result_code="$?"

    if (( result_code == 0 ))
    then
        if [[ -d "${temp_dir}" ]]
        then
            echo "Cleaning up temporary files..."
            rm -r "${temp_dir}"
        fi
        echo "Exiting download-updates.bash (normal exit)..."
    else
        # Keep temporary files for debugging
        printf '%s\n' "Keeping temporary files for debugging..."
        printf '%s\n' "Exiting download-updates.bash (error code ${result_code})..."
    fi

    echo ""
    exit "${result_code}"
} 1>&2
trap exit_handler EXIT

# ========== Functions ====================================================

function trace_on ()
{
    set -o xtrace
}

function trace_off ()
{
    set +o xtrace
}

function check_uid ()
{
    if (( "${UID}" == 0 ))
    then
        echo "This script should not be run as root."
        exit 1
    fi
    return 0
}

# Normalize the pathname of the script
#
# Possible values for uname -s are from:
#
# - https://en.wikipedia.org/wiki/Uname
# - https://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
#
# FreeBSD seems to use many typical GNU utilities, and a version of
# readlink, which is compatible with GNU readlink:
#
# - https://www.freebsd.org/cgi/man.cgi?query=readlink
#
# BSD readlink in Mac OS X is not a full replacement for GNU readlink:
#
# - https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac

function setup_working_directory ()
{
    if type -P uname > /dev/null
    then
        kernel_name="$(uname -s)"
        kernel_details="$(uname -a)"
        hardware_architecture="$(uname -m)"
    else
        echo "Unknown operation system"
        exit 1
    fi

    # Reveal the normalized, absolute pathname of the running script
    case "${kernel_name}" in
        Linux | FreeBSD | CYGWIN*)
            canonical_name="$(readlink -f "$0")"
        ;;
        Darwin | NetBSD | OpenBSD)
            # Use greadlink = GNU readlink, if available; otherwise use
            # BSD readlink, which lacks the option -f
            if type -P greadlink > /dev/null
            then
                canonical_name="$(greadlink -f "$0")"
            else
                canonical_name="$(readlink "$0")"
            fi
        ;;
        *)
            echo "Unknown operating system ${kernel_name}, ${OSTYPE}"
            exit 1
        ;;
    esac

    # Change to the home directory of the script
    #
    # TODO: basename and dirname can be replaced with bash parameter
    # expansions, but a complete replacement should also delete trailing
    # slashes.
    script_name="$(basename "${canonical_name}")"
    home_directory="$(dirname "${canonical_name}")"
    cd "${home_directory}" || exit 1

    # Calling dirname again reveals the enclosing wsusoffline directory,
    # using an absolute pathname. Then the directories cache, log and
    # timestamps can be defined as subdirectories of the wsusoffline
    # directory.
    #
    # Using absolute pathnames for all directories makes the usage of
    # hashdeep and curl more reliable, because these utilities often
    # require changes to the current working directory, and then relative
    # pathnames would not work anymore. This is a problem for writing
    # the logfile, which used to be defined as "../log/download.log".
    wsusoffline_directory="$(dirname "${home_directory}")"
    cache_dir="${wsusoffline_directory}/cache"
    log_dir="${wsusoffline_directory}/log"
    logfile="${log_dir}/download.log"
    timestamp_dir="${wsusoffline_directory}/timestamps"

    # Create subdirectories of the wsusoffline directory
    mkdir -p "${cache_dir}"
    mkdir -p "${log_dir}"
    mkdir -p "${timestamp_dir}"
    # Also create the directory ../static/sdd for an initial installation
    # of WSUS Offline Update by the Linux download scripts and for the
    # update of static download definitions (and other configuration
    # files)
    mkdir -p "${wsusoffline_directory}/static/sdd"

    return 0
}

function read_preferences ()
{
    if [[ -f ./preferences.bash ]]
    then
        # shellcheck disable=SC1091
        source ./preferences.bash
    fi
    return 0
}

# Run all scripts within a certain directory
#
# These scripts are considered libraries and "tasks", like common-tasks,
# update-generator-tasks and download-updates-tasks.
#
# Filename expansion (globbing) is done as suggested in
# http://mywiki.wooledge.org/BashFAQ/004 . This method is slightly
# elaborate, but it avoids some common problems with globbing:
#
# - The filename expansion is done within an indexed array. This is the
#   same format that the shell itself uses for file lists. It ensures,
#   that filenames with spaces or other problematic characters are
#   handled properly.
#
# - If there is no match, then the globbing pattern will be used as is,
#   but this may cause spurious error messages from external commands. For
#   example, "ls *.txt" returns the error message "The file *.txt was
#   not found", if there is no match at all. Such errors may be prevented
#   by temporarily setting the shell variable nullglob.
#
# - The next problem would be, that "ls *.txt" will show all files in the
#   current directory, if there is no match and the shell option nullglob
#   is set. Then the command would be "ls" without any arguments. This
#   can be prevented by iterating through all elements of the array. If
#   the array is empty, then the command will not be called at all.
#
# - Empty arrays are treated as "unset" by the shell, unlike empty
#   strings. If the shell option "nounset" is set, this would cause
#   another error. Testing the length of the array can prevent such
#   errors. This is a known bug in Bash up to version 4.3, as in Debian
#   8 Jessie. It is fixed in Bash version 4.4, as in Debian 9 Stretch:
#
#   bash: nounset treats empty array as unset, contrary to man. page
#   https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=529627

function run_tasks ()
{
    local task_directory="$1"
    local -a file_list=()
    local current_task=""

    if [[ -d "./${task_directory}" ]]
    then
        shopt -s nullglob
        file_list=( "./${task_directory}"/*.bash )
        shopt -u nullglob

        if (( "${#file_list[@]}" > 0 ))
        then
            for current_task in "${file_list[@]}"
            do
                # A new script 10-remove-obsolete-scripts.bash was added
                # to the directory common-tasks in version 1.0-beta-3. It
                # may remove obsolete scripts from previous versions. This
                # requires another check, if the files are still present.
                if [[ -f "${current_task}" ]]
                then
                    # shellcheck disable=SC1090
                    source "${current_task}"
                fi
            done
        fi
    else
        printf '%s\n' "Error: The directory ./${task_directory} was not found"
        exit 1
    fi
    return 0
}

# The last function should be a "main" function. But since all top-level
# code is already called "main" in the indexed array "${FUNCNAME[@]}",
# the main function should be called after the script name.

function download_updates ()
{
    check_uid
    setup_working_directory
    read_preferences
    run_tasks "libraries"
    run_tasks "common-tasks"
    run_tasks "download-updates-tasks"
    return 0
}

# ========== Commands =====================================================

# The only top-level code at this point should be a call of the main
# function.

download_updates "$@"
exit 0

# TODO: Set an error code, if runtime errors occurred
